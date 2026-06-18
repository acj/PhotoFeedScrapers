require "sqlite3"
require "fileutils"

class Store
  SCHEMA = <<~SQL
    CREATE TABLE IF NOT EXISTS photo_items (
      id            INTEGER PRIMARY KEY,
      source        TEXT    NOT NULL,
      photo_url     TEXT    NOT NULL UNIQUE,
      page_url      TEXT    NOT NULL,
      title         TEXT,
      caption       TEXT,
      pub_date      INTEGER,
      first_seen_at INTEGER NOT NULL
    );
    CREATE INDEX IF NOT EXISTS idx_pub_date      ON photo_items(pub_date DESC);
    CREATE INDEX IF NOT EXISTS idx_first_seen_at ON photo_items(first_seen_at DESC);
    CREATE INDEX IF NOT EXISTS idx_source        ON photo_items(source);
  SQL

  def initialize(path)
    FileUtils.mkdir_p(File.dirname(path))
    @db = SQLite3::Database.new(path)
    @db.results_as_hash = true
    @db.execute_batch(SCHEMA)
  end

  def upsert(item)
    now = Time.now.to_i
    @db.execute(
      <<~SQL,
        INSERT INTO photo_items (source, photo_url, page_url, title, caption, pub_date, first_seen_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(photo_url) DO UPDATE SET
          title    = excluded.title,
          caption  = excluded.caption,
          page_url = excluded.page_url,
          pub_date = COALESCE(photo_items.pub_date, excluded.pub_date)
      SQL
      [item.source, item.photo_url, item.page_url, item.title, item.caption, item.pub_date, now]
    )
    @db.changes
  end

  def recent(limit)
    @db.execute(<<~SQL, [limit])
      SELECT source, photo_url, page_url, title, caption, pub_date, first_seen_at
      FROM photo_items
      ORDER BY COALESCE(pub_date, first_seen_at) DESC, id DESC
      LIMIT ?
    SQL
  end

  def close
    @db.close
  end
end
