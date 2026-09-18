module "artifact_registry" {
  source = "./modules/artifact-registry"

  project_id    = var.project_id
  region        = var.region
  repository_id = "arahin"
  depends_on    = [google_project_service.apis]
}

locals {
  images = {
    parser  = "${module.artifact_registry.url}/arahin-parser:${var.image_tag}"
    ai      = "${module.artifact_registry.url}/arahin-ai:${var.image_tag}"
    backend = "${module.artifact_registry.url}/arahin-backend:${var.image_tag}"
  }
}

module "sa_parser" {
  source = "./modules/service-account"

  project_id   = var.project_id
  account_id   = "arahin-parser-run"
  display_name = "arahin-parser Cloud Run runtime"
  depends_on   = [google_project_service.apis]
}

module "sa_ai" {
  source = "./modules/service-account"

  project_id    = var.project_id
  account_id    = "arahin-ai-run"
  display_name  = "arahin-ai Cloud Run runtime"
  project_roles = ["roles/aiplatform.user"]
  depends_on    = [google_project_service.apis]
}

module "sa_backend" {
  source = "./modules/service-account"

  project_id    = var.project_id
  account_id    = "arahin-backend-run"
  display_name  = "arahin-backend Cloud Run runtime"
  project_roles = ["roles/cloudsql.client"]
  depends_on    = [google_project_service.apis]
}

module "network" {
  source = "./modules/private-network"

  project_id = var.project_id
  region     = var.region
  name       = "arahin"
  depends_on = [google_project_service.apis]
}

module "db" {
  source = "./modules/cloud-sql"

  project_id         = var.project_id
  region             = var.region
  instance_name      = "arahin-pg"
  private_network_id = module.network.network_id
  depends_on         = [google_project_service.apis, module.network]
}

module "parser_service" {
  source = "./modules/cloud-run-service"

  project_id            = var.project_id
  region                = var.region
  name                  = "arahin-parser"
  image                 = local.images.parser
  service_account_email = module.sa_parser.email
  timeout_seconds       = 150
  invoker_members       = ["serviceAccount:${module.sa_backend.email}"]

  env = {
    MAX_FILE_MB       = "25"
    PARSE_TIMEOUT_MS  = "120000"
    OCR_ENABLED       = "true"
    TESSDATA_PATH     = "/app/tessdata"
    OCR_FAILURE_FATAL = "false"
    EXTRACT_IMAGES    = "true"
    MAX_IMAGE_BYTES   = "8388608"
    MAX_IMAGE_COUNT   = "100"
  }
}

module "ai_service" {
  source = "./modules/cloud-run-service"

  project_id            = var.project_id
  region                = var.region
  name                  = "arahin-ai"
  image                 = local.images.ai
  service_account_email = module.sa_ai.email
  timeout_seconds       = 300
  invoker_members       = ["serviceAccount:${module.sa_backend.email}"]

  env = {
    GOOGLE_GENAI_USE_VERTEXAI = "true"
    GOOGLE_CLOUD_PROJECT      = var.project_id
    GOOGLE_CLOUD_LOCATION     = var.region
    GEMINI_MODEL              = "gemini-2.5-flash"
  }
}

module "backend_service" {
  source = "./modules/cloud-run-service"

  project_id            = var.project_id
  region                = var.region
  name                  = "arahin-backend"
  image                 = local.images.backend
  service_account_email = module.sa_backend.email
  timeout_seconds       = 300
  allow_unauthenticated = true
  cloudsql_instances    = [module.db.connection_name]
  vpc_network           = module.network.network_id
  vpc_subnetwork        = module.network.run_subnet_id

  env = merge(
    {
      APP_ENV                  = "production"
      JWT_TTL_HOURS            = "1"
      PARSER_BASE_URL          = module.parser_service.uri
      PARSER_TIMEOUT_SECONDS   = "150"
      AI_BASE_URL              = module.ai_service.uri
      AI_TIMEOUT_SECONDS       = "300"
      AI_MAX_ATTEMPTS          = "3"
      AI_RETRY_BASE_BACKOFF_MS = "500"
      AI_MAX_MARKDOWN_CHARS    = "200000"
      CORS_ORIGINS             = "*"
    },
    var.app_url == "" ? {} : { APP_URL = var.app_url },
  )

  secret_env = {
    JWT_SECRET   = { secret_id = google_secret_manager_secret.jwt_secret.secret_id }
    DATABASE_URL = { secret_id = google_secret_manager_secret.database_url.secret_id }
  }
}
