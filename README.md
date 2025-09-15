# PostgreSQL with zhparser Extension

这个项目提供了两个版本的PostgreSQL 17.6 Docker镜像，都包含了中文分词扩展 zhparser：

- **Alpine版本**: 基于 `postgres:17.6-alpine3.22` 构建的轻量级镜像
- **Debian版本**: 基于 `postgres:17.6` 构建的标准镜像

## 项目结构

```
postgre/
├── README.md                           # 本文档
├── alpine/
│   └── Dockerfile                      # Alpine版本的Dockerfile
├── debian/
│   └── Dockerfile                      # Debian版本的Dockerfile
└── docker-entrypoint-initdb.d/
    └── init-zhparser.sh               # zhparser扩展初始化脚本
```

## 特性

- **PostgreSQL 17.6**: 最新的PostgreSQL版本
- **zhparser**: 中文全文检索扩展，支持中文分词
- **SCWS**: Simple Chinese Word Segmentation (简单中文分词)
- **多架构支持**: 支持 x86_64 和 ARM64 架构
- **两种镜像选择**: Alpine (轻量级) 和 Debian (标准版)

## 镜像对比

| 特性 | Alpine版本 | Debian版本 |
|------|------------|------------|
| 基础镜像 | postgres:17.6-alpine3.22 | postgres:17.6 |
| 镜像大小 | ~200MB | ~400MB |
| 包管理器 | apk | apt |
| 启动速度 | 快 | 中等 |
| 兼容性 | 高 | 最高 |
| 推荐用途 | 生产环境、容器化部署 | 开发环境、需要额外工具 |

## 构建镜像

### Alpine版本 (推荐)

```bash
# 进入alpine目录
cd alpine

# 构建镜像
docker build -t longjianghu/postgres:17.6-alpine .
```

### Debian版本

```bash
# 进入debian目录
cd debian

# 构建镜像
docker build -t longjianghu/postgres:17.6 .
```

### 构建选项

构建时可以使用以下参数来优化构建过程：

```bash

# 构建多架构镜像（需要buildx）
docker buildx build --platform linux/amd64,linux/arm64 -t longjianghu/postgres:17.6 ./debian
docker buildx build --platform linux/amd64,linux/arm64 -t longjianghu/postgres:17.6-alpine ./alpine
```

## 使用方法

### 基本用法

#### 快速启动

```bash
# Alpine版本
docker run -d \
  --name postgres \
  -e POSTGRES_DB=mydb \
  -e POSTGRES_USER=myuser \
  -e POSTGRES_PASSWORD=mypassword \
  -p 5432:5432 \
  ongjianghu/postgres:17.6-alpine

# Debian版本
docker run -d \
  --name postgres-zh \
  -e POSTGRES_DB=mydb \
  -e POSTGRES_USER=myuser \
  -e POSTGRES_PASSWORD=mypassword \
  -p 5432:5432 \
  postgres-zhparser:17.6-debian
```

#### 使用docker-compose

创建 `docker-compose.yml` 文件：

```yaml
version: '3.8'

services:
  postgres:
    image: postgres-zhparser:17.6-alpine
    container_name: postgres-zh
    environment:
      POSTGRES_DB: mydb
      POSTGRES_USER: myuser
      POSTGRES_PASSWORD: mypassword
      POSTGRES_INITDB_ARGS: "--encoding=UTF-8 --lc-collate=C --lc-ctype=zh_CN.UTF-8"
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init-scripts:/docker-entrypoint-initdb.d
    restart: unless-stopped

volumes:
  postgres_data:
```

启动服务：

```bash
docker-compose up -d
```

### 高级配置

#### 持久化数据

```bash
docker run -d \
  --name postgres-zh \
  -e POSTGRES_DB=mydb \
  -e POSTGRES_USER=myuser \
  -e POSTGRES_PASSWORD=mypassword \
  -p 5432:5432 \
  -v postgres_data:/var/lib/postgresql/data \
  -v /path/to/your/init-scripts:/docker-entrypoint-initdb.d \
  postgres-zhparser:17.6-alpine
```

#### 自定义配置文件

```bash
docker run -d \
  --name postgres-zh \
  -e POSTGRES_DB=mydb \
  -e POSTGRES_USER=myuser \
  -e POSTGRES_PASSWORD=mypassword \
  -p 5432:5432 \
  -v postgres_data:/var/lib/postgresql/data \
  -v /path/to/postgresql.conf:/etc/postgresql/postgresql.conf \
  -v /path/to/pg_hba.conf:/etc/postgresql/pg_hba.conf \
  postgres-zhparser:17.6-alpine \
  -c 'config_file=/etc/postgresql/postgresql.conf'
```

## zhparser 使用示例

### 连接到数据库

```bash
# 使用psql连接
docker exec -it postgres-zh psql -U myuser -d mydb

# 或者从外部连接
psql -h localhost -p 5432 -U myuser -d mydb
```

### 使用中文分词功能

```sql
-- zhparser扩展会自动创建并配置
-- 检查扩展是否已安装
\dx zhparser

-- 查看中文分词配置
\dF zhcfg

-- 测试中文分词
SELECT to_tsvector('zhcfg', '中华人民共和国成立于1949年');

-- 创建包含中文的表
CREATE TABLE articles (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200),
    content TEXT,
    search_vector TSVECTOR
);

-- 插入测试数据
INSERT INTO articles (title, content) VALUES
('中国历史', '中华人民共和国成立于1949年10月1日'),
('科技发展', '人工智能和机器学习正在改变世界'),
('自然环境', '保护环境是每个人的责任和义务');

-- 更新搜索向量
UPDATE articles SET search_vector = to_tsvector('zhcfg', title || ' ' || content);

-- 创建索引提高搜索性能
CREATE INDEX idx_articles_search ON articles USING gin(search_vector);

-- 中文全文搜索示例
SELECT title, content 
FROM articles 
WHERE search_vector @@ to_tsquery('zhcfg', '中国 | 人工智能');

-- 搜索结果排序
SELECT title, content, ts_rank(search_vector, query) as rank
FROM articles, to_tsquery('zhcfg', '中国') query
WHERE search_vector @@ query
ORDER BY rank DESC;
```

### 高级搜索功能

```sql
-- 短语搜索
SELECT title FROM articles 
WHERE search_vector @@ phraseto_tsquery('zhcfg', '人民共和国');

-- 模糊搜索
SELECT title FROM articles 
WHERE search_vector @@ websearch_to_tsquery('zhcfg', '中国 历史');

-- 高亮搜索结果
SELECT title, 
       ts_headline('zhcfg', content, to_tsquery('zhcfg', '中国'), 'StartSel=<mark>, StopSel=</mark>') as highlighted_content
FROM articles 
WHERE search_vector @@ to_tsquery('zhcfg', '中国');
```

## 健康检查

检查容器状态：

```bash
# 检查容器是否运行
docker ps | grep postgres-zh

# 查看容器日志
docker logs postgres-zh

# 检查数据库连接
docker exec postgres-zh pg_isready -U myuser

# 检查zhparser扩展
docker exec -it postgres-zh psql -U myuser -d mydb -c "\dx zhparser"
```

## 性能优化

### PostgreSQL配置优化

创建自定义的 `postgresql.conf`:

```ini
# 内存设置
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB
maintenance_work_mem = 64MB

# 连接设置
max_connections = 200
shared_preload_libraries = 'zhparser'

# 日志设置
log_statement = 'all'
log_duration = on
log_min_duration_statement = 1000

# 中文设置
lc_messages = 'zh_CN.UTF-8'
lc_monetary = 'zh_CN.UTF-8'
lc_numeric = 'zh_CN.UTF-8'
lc_time = 'zh_CN.UTF-8'
```

### 索引优化

```sql
-- 为中文搜索创建专门的索引
CREATE INDEX CONCURRENTLY idx_articles_gin_zh ON articles USING gin(to_tsvector('zhcfg', content));

-- 部分索引（只为有内容的行创建索引）
CREATE INDEX idx_articles_content_zh ON articles USING gin(to_tsvector('zhcfg', content))
WHERE content IS NOT NULL AND content != '';

-- 表达式索引
CREATE INDEX idx_articles_title_content_zh ON articles 
USING gin(to_tsvector('zhcfg', coalesce(title,'') || ' ' || coalesce(content,'')));
```

## 故障排除

### 常见问题

1. **扩展未安装**
   ```sql
   -- 手动创建扩展
   CREATE EXTENSION IF NOT EXISTS zhparser;
   ```

2. **中文分词配置不存在**
   ```sql
   -- 手动创建分词配置
   CREATE TEXT SEARCH CONFIGURATION zhcfg (PARSER = zhparser);
   ALTER TEXT SEARCH CONFIGURATION zhcfg ADD MAPPING FOR n,v,a,i,e,l WITH simple;
   ```

3. **权限问题**
   ```bash
   # 确保数据库用户有创建扩展的权限
   docker exec -it postgres-zh psql -U postgres -c "ALTER USER myuser CREATEDB;"
   ```

4. **连接问题**
   ```bash
   # 检查端口是否正确映射
   docker port postgres-zh
   
   # 检查防火墙设置
   sudo ufw status
   ```

### 调试模式

启动调试模式的容器：

```bash
docker run -it --rm \
  -e POSTGRES_DB=mydb \
  -e POSTGRES_USER=myuser \
  -e POSTGRES_PASSWORD=mypassword \
  postgres-zhparser:17.6-alpine \
  bash
```

## 备份和恢复

### 数据备份

```bash
# 备份单个数据库
docker exec postgres-zh pg_dump -U myuser mydb > backup.sql

# 备份所有数据库
docker exec postgres-zh pg_dumpall -U postgres > full_backup.sql

# 使用压缩备份
docker exec postgres-zh pg_dump -U myuser -Fc mydb > backup.dump
```

### 数据恢复

```bash
# 从SQL文件恢复
docker exec -i postgres-zh psql -U myuser mydb < backup.sql

# 从压缩文件恢复
docker exec -i postgres-zh pg_restore -U myuser -d mydb backup.dump
```

## 安全建议

1. **使用强密码**
   ```bash
   # 生成强密码
   openssl rand -base64 32
   ```

2. **限制网络访问**
   ```yaml
   # 在docker-compose.yml中只暴露给内部网络
   networks:
     - internal
   ```

3. **使用非root用户**
   ```dockerfile
   # 在Dockerfile中已经使用postgres用户
   USER postgres
   ```

4. **定期更新镜像**
   ```bash
   # 重新构建镜像获取最新的安全补丁
   docker build --no-cache -t postgres-zhparser:17.6-alpine .
   ```

## 更新和维护

### 更新PostgreSQL版本

1. 修改Dockerfile中的基础镜像版本
2. 重新构建镜像
3. 备份现有数据
4. 使用新镜像启动容器
5. 恢复数据并测试

### 监控

使用Docker的健康检查：

```dockerfile
# 在Dockerfile中添加
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD pg_isready -U $POSTGRES_USER -d $POSTGRES_DB || exit 1
```

## 贡献指南

欢迎提交Issue和Pull Request来改进这个项目。

### 开发环境设置

```bash
git clone <your-repo-url>
cd postgre
```

### 测试

```bash
# 构建并测试Alpine版本
cd alpine && docker build -t test-postgres-zh-alpine .
docker run --rm -e POSTGRES_PASSWORD=test test-postgres-zh-alpine postgres --version

# 构建并测试Debian版本
cd debian && docker build -t test-postgres-zh-debian .
docker run --rm -e POSTGRES_PASSWORD=test test-postgres-zh-debian postgres --version
```

## 许可证

本项目使用 MIT 许可证。详情请参见 LICENSE 文件。

## 相关链接

- [PostgreSQL官方文档](https://www.postgresql.org/docs/)
- [zhparser GitHub仓库](https://github.com/amutu/zhparser)
- [SCWS官方网站](http://www.xunsearch.com/scws/)
- [Docker Hub PostgreSQL](https://hub.docker.com/_/postgres)