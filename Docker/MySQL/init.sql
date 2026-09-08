-- DB名・ユーザー・パスワードは、　.env --> docker-compose.yml --> MySQL　に任せる

USE snsapp;

-- アカウントID
CREATE TABLE
    users (
        id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
        name VARCHAR(10) NOT NULL,
        email VARCHAR(255) NOT NULL,
        password VARCHAR(255) NOT NULL,
        created_at DATETIME (6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
        updated_at DATETIME (6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
        PRIMARY KEY (id),
        UNIQUE KEY uq_users_email (email)
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- 投稿ID
CREATE TABLE
    posts (
        id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
        user_id BIGINT UNSIGNED NOT NULL,
        content TEXT NOT NULL,
        study_time TIME NOT NULL,
        created_at DATETIME (6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
        updated_at DATETIME (6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
        deleted_at DATETIME (6) DEFAULT NULL,
        PRIMARY KEY (id),
        KEY idx_posts_user_id (user_id),
        CONSTRAINT fk_posts_user FOREIGN KEY (user_id) REFERENCES users (id)
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- コメントID
CREATE TABLE
    comments (
        id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
        user_id BIGINT UNSIGNED NOT NULL,
        post_id BIGINT UNSIGNED NOT NULL,
        content TEXT NOT NULL,
        created_at DATETIME (6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
        updated_at DATETIME (6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
        deleted_at DATETIME (6) DEFAULT NULL,
        PRIMARY KEY (id),
        KEY idx_comments_user_id (user_id),
        KEY idx_comments_post_id (post_id),
        CONSTRAINT fk_comments_user FOREIGN KEY (user_id) REFERENCES users (id),
        CONSTRAINT fk_comments_post FOREIGN KEY (post_id) REFERENCES posts (id)
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- 課題ID
CREATE TABLE
    tasks (
        id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
        content TEXT NOT NULL,
        PRIMARY KEY (id),
        created_at DATETIME (6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
        updated_at DATETIME (6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6)
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- チェーン管理テーブル
CREATE TABLE chain (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
)ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE 
    Baton (
        id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,           -- バトンID
        baton_title VARCHAR(25) NOT NULL,                              -- バトンタイトル
        sender_id   BIGINT UNSIGNED NOT NULL,                          -- 送信者ID
        receiver_id BIGINT UNSIGNED NOT NULL,                          -- 受信者ID
        task_id     BIGINT UNSIGNED NOT NULL,                          -- 課題ID
        content     TEXT NOT NULL,                                     -- バトン内容
        chain_id    BIGINT UNSIGNED NOT NULL,                          -- チェインID
        relay_count BIGINT UNSIGNED NOT NULL,                          -- 今何人目か
        status      TINYINT NOT NULL DEFAULT 0,                        -- ステータス(0:未完了 1:完了 2:失敗)
        batonpop    TINYINT NOT NULL DEFAULT 0,                        -- 通知フラグ(0:未通知 1:通知済み)
        get_at      DATETIME(6) DEFAULT NULL,                          -- 受け取り日時
        release_at  DATETIME(6) DEFAULT NULL,                          -- 渡し日時
        created_at  DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6), -- 作成日時
        updated_at  DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6), -- 更新日時
        PRIMARY KEY (id),
        KEY idx_baton_sender_id   (sender_id),
        KEY idx_baton_receiver_id (receiver_id),
        KEY idx_baton_task_id     (task_id),
        KEY idx_baton_chain_id    (chain_id),
        KEY idx_baton_created_at  (created_at),
        CONSTRAINT fk_baton_sender   FOREIGN KEY (sender_id)   REFERENCES users (id),
        CONSTRAINT fk_baton_receiver FOREIGN KEY (receiver_id) REFERENCES users (id),
        CONSTRAINT fk_baton_task     FOREIGN KEY (task_id)     REFERENCES tasks (id),
        CONSTRAINT fk_chain_id       FOREIGN KEY (chain_id)    REFERENCES chain (id)
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- バトン予約テーブル
CREATE TABLE baton_queues (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    baton_title VARCHAR(25) NOT NULL,
    sender_id  BIGINT UNSIGNED NOT NULL,
    chain_id   BIGINT UNSIGNED NOT NULL,
    task_id    BIGINT UNSIGNED NOT NULL,                          -- 課題ID
    content    TEXT NOT NULL,                                     -- バトン内容
    relay_count BIGINT UNSIGNED NOT NULL,
    created_at  DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    KEY idx_baton_queues_sender_id   (sender_id),
    KEY idx_baton_queues_chain_id   (chain_id),
    KEY idx_baton_queues_created_at   (created_at)
)ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- バトン履歴ID
CREATE TABLE
    Batonlogs (
        id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
        baton_id BIGINT UNSIGNED NOT NULL,
        content TEXT NOT NULL,
        logs_F BIT(1),
        created_at DATETIME (6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
        PRIMARY KEY (id),
        KEY idx_batonlogs_user_id (baton_id),
        CONSTRAINT fk_batonlogs_user FOREIGN KEY (baton_id) REFERENCES Baton (id)
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- リアクションID
CREATE TABLE
    post_reactions (
        id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,     -- リアクションID 主キー
        post_id BIGINT UNSIGNED NOT NULL,               -- 投稿id参照　外部キー
        user_id BIGINT UNSIGNED NOT NULL,               -- ユーザーid参照　外部キー
        emoji_type VARCHAR(50)  COLLATE utf8mb4_bin NOT NULL,                -- スタンプ内容
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- リアクション日時
        PRIMARY KEY (id),
        UNIQUE KEY unique_user_reaction(post_id,user_id,emoji_type), -- 同じ人が同じリアクションをしないようにする制約
        FOREIGN KEY (post_id) REFERENCES posts (id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        -- ON DELETE CASCADE 連動削除機能。投稿が消えると紐づいているリアクションも一緒に消える
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- リアクションID
CREATE TABLE
    comment_reactions (
        id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,     -- リアクションID 主キー
        comment_id BIGINT UNSIGNED NOT NULL,  
        user_id BIGINT UNSIGNED NOT NULL,               -- ユーザーid参照　外部キー
        emoji_type VARCHAR(50)  COLLATE utf8mb4_bin NOT NULL,                -- スタンプ内容
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- リアクション日時
        PRIMARY KEY (id),
        UNIQUE KEY unique_user_reaction(comment_id,user_id,emoji_type), -- 同じ人が同じリアクションをしないようにする制約
        FOREIGN KEY (comment_id) REFERENCES comments (id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        -- ON DELETE CASCADE 連動削除機能。投稿が消えると紐づいているリアクションも一緒に消える
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;    

INSERT INTO tasks(content)
VALUES
('今日授業で習ったこと、1つ教えて！') ,
('最近のマナビで「へーー」って思ったこと教えてー') ,
('得意な教科の問題、何でもいいから3問解いてみて！') ,
('苦手な教科の教科書を1ページだけ音読しろ') ,
('「これ知らんやろ」って思ってること教えて') ,
('昨日より1ミリだけ賢くなったこと教えて') ,
('ノートのどっか1行だけ写してみて') ,
('今日の授業で一番どうでもよかったこと教えて') ,
('3分だけ何か勉強して「やった」って言い切れ') ,
('英単語1個だけ覚えてドヤって') ,
('「これテスト出そう」って勝手に予想してみて') ,
('今日の先生の話で一番印象に残ったフレーズ教えて') ,
('数学でも英語でもいいから“1問だけ”倒してこい') ,
('「なんとなく理解した気がする」ことを説明してみて') ,
('30秒だけ教科書読んで、覚えてる単語3つ書け') ,
('友達に1つだけ勉強の話ふってみて（内容も書け）') ,
('今日の授業を一言でまとめろ（雑でOK）') ,
('「これ誰かに教えたい」って思うこと1つ書いて') ,
('過去の自分に1行だけアドバイスするとしたら？') ,
('「これ一生使わんやろ」って思った知識教えて') ,
('勉強に関係ありそうでなさそうな豆知識1つ') ,
('今日の集中力を10点満点で評価して理由もどうぞ') ,
('1分だけタイマーなしで集中してみて感想書け') ,
('今の気分で一番マシな教科に1秒触れろ（開くだけOK）') ;

INSERT INTO chain(id) VALUES(1);