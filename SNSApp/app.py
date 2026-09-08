# 【重要】サーバーが「一度にたくさんの仕事」を並行してこなせるようにする魔法の設定
# これがないと、1人の処理中に他の人の通信が止まって（ロックして）しまいます
# from gevent import monkey
# monkey.patch_all()

from flask import Flask, request, redirect, render_template, session, url_for
from flask_socketio import join_room,emit
from extensions import socketio
from flask_wtf.csrf import CSRFProtect
from datetime import timedelta
from Models.Baton import Baton
from Models.BatonRepository import BatonRepository
from routes.auth import auth
from routes.posts import posts
from routes.baton import baton
from routes.ranking import ranking
from util.SessionManager import SessionManager as SM
from services.baton_services import baton_services
from util.DB import DB
import uuid
import os

db_pool = DB.init_db_pool()

# 定数定義
SESSION_DAYS = 30

app = Flask(__name__)

# アプリのシークレットキー
app.secret_key = os.getenv('SECRET_KEY', uuid.uuid4().hex)

# セッションの有効期限を設定
app.permanent_session_lifetime = timedelta(days=SESSION_DAYS)

# CSRF対策
csrf = CSRFProtect(app)

# リアルタイム通知
socketio.init_app(app)

# -- ルーティング登録 --
# 認証系（ログイン・ログアウト・登録）
app.register_blueprint(auth)

# 投稿系（投稿一覧・作成・削除）
app.register_blueprint(posts)

#バトン系
app.register_blueprint(baton)

#ランキング系
app.register_blueprint(ranking)

# ルートページのリダイレクト処理
@app.route('/', methods=['GET'])
def index():
    # セッションが無効の場合
    if not SM.is_live_session():
        # ログインページ表示
        return redirect(url_for('auth.login_view'))

    # 投稿一覧ページ    
    return redirect(url_for('posts.mypage_view'))


# クライアントが接続したとき、ユーザーIDのroomに参加する
@socketio.on('connect')
def on_connect():
    if not SM.is_live_session():
        return    
    
    # ユーザーID取得
    user_id = SM.get_user_id()
    
    # ルームに参加させる
    join_room(str(user_id))

    # 24時間経過したバトン取得（通知するため）
    expired_batons = Baton.get_expired_batons()

    if expired_batons:
        try:
            conn = db_pool.get_conn()
            
            # 失敗扱いにする
            BatonRepository.update_expired_status(conn)
            
            # ユーザーごとに、失敗メッセージを通知
            for expired_baton in expired_batons:
                emit('notification'
                    , {'message': 'バトン失敗・・・\r\n次は頑張ろう！'}
                    , room=str(expired_baton['receiver_id']))  
                
            
            # コミット
            conn.commit()
        
        except Exception as e:
            conn.rollback()
        finally:
            db_pool.release(conn)

    # 空いている人に自動で割り振る
    conn2 = db_pool.get_conn()
    try:
        baton_services.assign_waiting_baton_if_possible(conn2)
        conn2.commit()
    except Exception as e:
        conn2.rollback()
    finally:
        db_pool.release(conn2)                

    # バトンが渡されていた場合
    current_task = Baton.get_by_incomplete_baton(user_id)
    
    # 未通知の場合のみ
    if current_task and current_task['batonpop'] == 0:
        emit('notification'
            , {
                'message': 'バトンが渡されました！\r\n確認してみよう！'
               ,'baton_id':current_task['id']
               ,'reload':True
               }
            , room=str(user_id))  
 


# -- 通知が届いた場合、Batonを通知済みにする --
@socketio.on('notification_received')
def notification_received(data):
    # セッション切れていたら、何もしない
    if not SM.is_live_session():
        return    
    
    # ログイン中のユーザーID取得
    user_id = SM.get_user_id()
    baton_id = data.get('baton_id')
    print(baton_id)

    if not baton_id:
        return

    # 既存のメソッドを使って、このユーザーの未完了バトンを取得
    current_task = Baton.get_by_incomplete_baton(user_id)

    print(current_task['id'])
    
    if current_task and current_task['id'] == baton_id:
        Baton.mark_as_read(baton_id)


@app.errorhandler(400)
def bad_request(error):
    return render_template('error/400.html'), 400

@app.errorhandler(404)
def page_not_found(error):
    return render_template('error/404.html'),404

@app.errorhandler(500)
def internal_server_error(error):
    return render_template('error/500.html'),500

if __name__ == '__main__':
     socketio.run(app, host="0.0.0.0", debug=False) #内部のデバッグ情報をブラウザに公開しないように debug=False
