# راهنمای ساخت Docker Image برای Sourcegraph

## بررسی ساختار Docker Image

بر اساس بررسی کدهای پروژه و لایه‌های Docker که ارائه دادید، Docker image رسمی Sourcegraph از نوع **all-in-one server** است که شامل تمامی کامپوننت‌های ضروری می‌باشد:

### کامپوننت‌های موجود در Server Image

1. **Backend Services** (از فایل `cmd/server/BUILD.bazel:88-98`):
   - `frontend` - API Gateway و وب سرور
   - `gitserver` - مدیریت repository های Git
   - `searcher` - جستجوی غیر indexed
   - `repo-updater` - همگام‌سازی repositories
   - `symbols` - استخراج symbols کد
   - `worker` - پردازش background jobs
   - `precise-code-intel-worker` - پردازش code intelligence
   - `embeddings` - سرویس embeddings
   - `migrator` - مدیریت database migrations

2. **Zoekt Services** (از فایل `cmd/server/BUILD.bazel:100-105`):
   - `zoekt-webserver` - سرور جستجوی indexed
   - `zoekt-sourcegraph-indexserver` - ایجاد index ها
   - `zoekt-git-index` - ابزار indexing
   - `zoekt-archive-index` - ابزار indexing آرشیو

3. **Frontend Assets** (از فایل `cmd/server/BUILD.bazel:181`):
   - `client/web/dist:tar_bundle` - تمام فایل‌های static frontend

4. **Infrastructure Components** (از فایل `wolfi-images/server.yaml`):
   - PostgreSQL 12 - دیتابیس اصلی
   - Redis 6.2 - کش و صف‌ها
   - Nginx - وب سرور
   - Prometheus - مانیتورینگ
   - Grafana 7 - داشبوردهای مانیتورینگ
   - Jaeger - distributed tracing

## روش‌های ساخت Docker Image

### روش 1: استفاده از `sg` (ساده‌ترین روش)

```bash
# ساخت و لود کردن image در Docker
sg images build --load server

# یا فقط ساخت image بدون لود کردن
sg images build --no-load server
```

**مزایا:**
- ساده‌ترین روش
- تمام تنظیمات از قبل انجام شده
- مناسب برای توسعه محلی

### روش 2: استفاده مستقیم از Bazel

```bash
# ساخت image tarball
bazel build //cmd/server:image_tarball

# لود کردن در Docker
bazel run //cmd/server:image_tarball
```

**مزایا:**
- کنترل بیشتر بر روی فرآیند build
- امکان بررسی دقیق‌تر خروجی

### روش 3: استفاده از اسکریپت‌های آماده

```bash
# استفاده از اسکریپت ساده شده
./build-sourcegraph.sh
```

این اسکریپت:
1. بررسی می‌کند که bazel/bazelisk نصب باشد
2. دستورات Bazel مناسب را اجرا می‌کند
3. Image را با تگ `server:candidate` می‌سازد

## جزئیات فنی Build Process

### 1. Base Image
- استفاده از Wolfi Linux (مشابه Alpine اما امن‌تر)
- تعریف شده در: `wolfi-images/server.yaml`
- شامل تمام dependencies سیستمی مورد نیاز

### 2. Build Steps (از `cmd/server/BUILD.bazel`):

```python
# تعریف base image
wolfi_base()  # خط 212

# ساخت image اصلی
oci_image(
    name = "image",
    base = ":base_image",
    entrypoint = ["/sbin/tini", "--", "/server"],
    tars = [
        # باینری‌های اصلی
        ":tar_server",
        # تنظیمات
        ":static_config_tar",
        ":tar_postgres_exporter_config",
        ":tar_monitoring_config",
        # ابزارهای کمکی
        ":tar_syntax-highlighter",
        ":tar_scip-ctags",
        # اسکریپت‌های PostgreSQL
        ":tar_postgres_optimize",
        ":tar_postgres_reindex",
        # Prometheus wrapper
        ":tar_prom-wrapper",
        # اسکریپت‌های تست
        ":tar_image_test_scripts",
        # Frontend bundle
        "//client/web/dist:tar_bundle",
        # Grafana dashboards
        "//monitoring:generate_grafana_config_tar",
    ] + dependencies_tars(DEPS) + dependencies_tars(ZOEKT_DEPS),
)
```

### 3. نحوه Package کردن Components

هر کامپوننت به صورت جداگانه compile و در `/usr/local/bin` قرار می‌گیرد:
- از macro `container_dependencies` (در `cmd/server/macro.bzl`)
- هر باینری در یک `pkg_tar` جداگانه
- تمام tar ها در image نهایی ترکیب می‌شوند

## اجرای Image ساخته شده

```bash
# مشاهده image
docker images | grep server:candidate

# اجرای image
docker run -d \
  --name sourcegraph \
  -p 7080:7080 \
  -p 3370:3370 \
  -v /path/to/data:/var/opt/sourcegraph \
  server:candidate

# یا با تنظیمات بیشتر
docker run -d \
  --name sourcegraph \
  -p 7080:7080 \
  -p 3370:3370 \
  -e DEPLOY_TYPE=docker-compose \
  -e SOURCEGRAPH_EXTERNAL_URL=http://localhost:7080 \
  -v sourcegraph-data:/var/opt/sourcegraph \
  server:candidate
```

## نکات مهم

1. **حجم Image**: حدود 1.3GB (بر اساس لایه‌های ارائه شده)
   - Base image (Wolfi): ~532MB
   - Frontend bundle: ~176MB
   - Backend services: ~500MB مجموع
   - Infrastructure: ~200MB

2. **تگ‌های Image**:
   - Build محلی: `server:candidate`
   - برای production باید تگ مناسب بدهید:
     ```bash
     docker tag server:candidate my-registry/sourcegraph:v1.0
     ```

3. **محیط Development**:
   - از `sg.config.yaml` برای تنظیمات محلی استفاده می‌شود
   - می‌توانید `sg.config.overwrite.yaml` برای تنظیمات شخصی ایجاد کنید

4. **Build Cache**:
   - Bazel از cache استفاده می‌کند
   - برای clean build: `bazel clean --expunge`

## Troubleshooting

### اگر Bazel نصب نیست:
```bash
# دانلود bazelisk
curl -Lo bazelisk https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-amd64
chmod +x bazelisk
```

### اگر build fail می‌شود:
1. بررسی logs: `bazel build //cmd/server:image_tarball --verbose_failures`
2. بررسی dependencies: `sg doctor`
3. پاک کردن cache: `bazel clean`

### برای دیدن دقیق محتوای image:
```bash
# لیست دقیق آنچه build می‌شود
bazel cquery '//cmd/server:image' --output build

# بررسی dependencies
bazel query 'deps(//cmd/server:image)'
```

## خلاصه

Image ای که با دستورات بالا می‌سازید، دقیقاً مشابه image رسمی `sourcegraph/server` است و شامل:
- تمام backend services
- PostgreSQL و Redis
- Frontend (React app)
- مانیتورینگ (Prometheus/Grafana)
- تمام ابزارهای جانبی

این یک **all-in-one** image است که برای deployment های کوچک تا متوسط مناسب است.