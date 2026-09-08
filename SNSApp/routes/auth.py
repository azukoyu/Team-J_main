from flask import Blueprint,request,redirect, render_template, session,url_for,flash
from Models.User import User
from Models.Post import Post
from Models.Comment import Comment
from util.SessionManager import SessionManager as SM
import re
from werkzeug.security import generate_password_hash, check_password_hash
import os

auth = Blueprint('auth', __name__)

EMAIL_PATTERN = r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$"
INVITE_CODE = os.environ.get('INVITE_CODE')

# 新規登録ページの表示
@auth.route('/signup', methods=['GET'])
def signup_view():
    # ログイン済みの場合は投稿一覧へ
    if SM.is_live_session():
        return redirect(url_for('posts.mypage_view'))
    
    return render_template('auth/signup.html')


# ログインページの表示
@auth.route('/login', methods=['GET'])
def login_view():
    # ログイン済みの場合は投稿一覧へ
    if SM.is_live_session():
        return redirect(url_for('posts.mypage_view'))
    
    return render_template('auth/login.html')

# ログイン処理
@auth.route('/login', methods=['POST'])
def login_process():
    email = request.form.get('email')
    password = request.form.get('password_confirmation')

    # ログイン不正
    if email.strip() =='' or password.strip() == '':
        flash('メールアドレスorパスワードが空です','error')
        return redirect(url_for('auth.login_view'))
    
    # メールアドレスでユーザー情報検索
    user = User.find_by_email(email)
    
    # ユーザーが見つからなかった場合
    if user is None:
        flash('メールアドレスorパスワードが違います','error')
        return redirect(url_for('auth.login_view'))
    
    # パスワードが一致しない場合
    if not check_password_hash(user["password"], password):
        flash('メールアドレスorパスワードが違います','error')
        return redirect(url_for('auth.login_view'))
    
    # ログイン成功
    # セッション情報作成
    SM.create_session(user["id"])
    return redirect(url_for('posts.mypage_view'))

# 新規登録
@auth.route('/signup', methods=['POST'])
def signup_process():
    name = request.form.get('username', '').strip()
    email = request.form.get('email', '').strip()
    password = request.form.get('password', '')
    password_confirmation = request.form.get('password_confirmation', '')
    invite_code = request.form.get('invite_code', '').strip()
    
    # 空チェック
    if not name or not email or not password or not password_confirmation or not invite_code:
        flash("空のフォームがあります" , 'error')
        return redirect(url_for('auth.signup_view'))

    # 招待コードチェック
    if invite_code != INVITE_CODE:
        flash('招待コードが正しくありません', 'error')
        return redirect(url_for('auth.signup_view'))

    # パスワード一致チェック
    if password != password_confirmation:
        flash('二つのパスワードの値が違っています','error')
        return redirect(url_for('auth.signup_view'))

    # メール形式チェック
    if re.match(EMAIL_PATTERN, email) is None:
        flash('正しいメールアドレスの形式ではありません','error')
        return redirect(url_for('auth.signup_view'))

    # 既存ユーザーチェック
    registered_user = User.find_by_email(email)
    if registered_user is not None:
        flash('既に登録されているメールアドレスです','error')
        return redirect(url_for('auth.signup_view'))

    # パスワード保存用の安全なハッシュを生成
    hashed_password = generate_password_hash(password)

    # 新規登録
    user_id = User.create(name, email, hashed_password)

    # セッション情報作成
    SM.create_session(user_id)

    return redirect(url_for('posts.mypage_view'))


# ログアウト
@auth.route('/logout')
def logout():
    # セッションクリア
    SM.clear_session()
    return redirect(url_for('auth.login_view'))