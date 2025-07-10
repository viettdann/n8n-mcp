-- Optimized schema with source code storage for Docker optimization
CREATE TABLE IF NOT EXISTS nodes (
  node_type TEXT PRIMARY KEY,
  package_name TEXT NOT NULL,
  display_name TEXT NOT NULL,
  description TEXT,
  category TEXT,
  development_style TEXT CHECK(development_style IN ('declarative', 'programmatic')),
  is_ai_tool INTEGER DEFAULT 0,
  is_trigger INTEGER DEFAULT 0,
  is_webhook INTEGER DEFAULT 0,
  is_versioned INTEGER DEFAULT 0,
  version TEXT,
  documentation TEXT,
  properties_schema TEXT,
  operations TEXT,
  credentials_required TEXT,
  -- New columns for source code storage
  node_source_code TEXT,
  credential_source_code TEXT,
  source_location TEXT,
  source_extracted_at DATETIME,
  -- Metadata
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_package ON nodes(package_name);
CREATE INDEX IF NOT EXISTS idx_ai_tool ON nodes(is_ai_tool);
CREATE INDEX IF NOT EXISTS idx_category ON nodes(category);

-- Templates table for n8n workflow templates
CREATE TABLE IF NOT EXISTS templates (
  id INTEGER PRIMARY KEY,
  workflow_id INTEGER UNIQUE NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  author_name TEXT,
  author_username TEXT,
  author_verified INTEGER DEFAULT 0,
  nodes_used TEXT, -- JSON array of node types
  workflow_json TEXT NOT NULL, -- Complete workflow JSON
  categories TEXT, -- JSON array of categories
  views INTEGER DEFAULT 0,
  created_at DATETIME,
  updated_at DATETIME,
  url TEXT,
  scraped_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Templates indexes
CREATE INDEX IF NOT EXISTS idx_template_nodes ON templates(nodes_used);
CREATE INDEX IF NOT EXISTS idx_template_updated ON templates(updated_at);
CREATE INDEX IF NOT EXISTS idx_template_name ON templates(name);

-- Full-text search for templates
CREATE VIRTUAL TABLE IF NOT EXISTS templates_fts USING fts5(
  name, description, content=templates
);

-- FTS5 table for full-text search including source code
CREATE VIRTUAL TABLE IF NOT EXISTS nodes_fts USING fts5(
  node_type,
  display_name,
  description,
  documentation,
  operations,
  node_source_code,
  content=nodes,
  content_rowid=rowid
);

-- Trigger to keep FTS in sync
CREATE TRIGGER IF NOT EXISTS nodes_fts_insert AFTER INSERT ON nodes
BEGIN
  INSERT INTO nodes_fts(rowid, node_type, display_name, description, documentation, operations, node_source_code)
  VALUES (new.rowid, new.node_type, new.display_name, new.description, new.documentation, new.operations, new.node_source_code);
END;

CREATE TRIGGER IF NOT EXISTS nodes_fts_update AFTER UPDATE ON nodes
BEGIN
  UPDATE nodes_fts 
  SET node_type = new.node_type,
      display_name = new.display_name,
      description = new.description,
      documentation = new.documentation,
      operations = new.operations,
      node_source_code = new.node_source_code
  WHERE rowid = new.rowid;
END;

CREATE TRIGGER IF NOT EXISTS nodes_fts_delete AFTER DELETE ON nodes
BEGIN
  DELETE FROM nodes_fts WHERE rowid = old.rowid;
END;