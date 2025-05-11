resource "aws_appconfig_application" "feature_flags_app" {
  name = "${var.environment}-minebitcoinonline-feature-flags"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_appconfig_environment" "feature_flags_env" {
  application_id = aws_appconfig_application.feature_flags_app.id
  name           = var.environment

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_appconfig_configuration_profile" "feature_flags_profile" {
  application_id = aws_appconfig_application.feature_flags_app.id
  location_uri   = "hosted"
  name           = "feature-flags"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Hosted Configuration (initial version)
resource "aws_appconfig_hosted_configuration_version" "initial_feature_flags_version" {
  application_id        = aws_appconfig_application.feature_flags_app.id
  configuration_profile_id = aws_appconfig_configuration_profile.feature_flags_profile.configuration_profile_id
  content_type          = "application/json"
  content               = jsonencode(merge(
    # Feature flags for all environments
    {
       "testFeature1": true
    },
    # Feature flags for dev environment
    var.environment == "dev" ? {
      "devAccessEnabled": true
    } : {}
  ))

  depends_on = [
    aws_appconfig_configuration_profile.feature_flags_profile
  ]
}

resource "aws_appconfig_deployment_strategy" "feature_flags_strategy" {
  name                              = "${var.environment}-minebitcoinonline-linear-strategy"
  deployment_duration_in_minutes    = 0
  final_bake_time_in_minutes        = 0
  growth_factor                     = 100
  growth_type                       = "LINEAR"
  replicate_to                      = "NONE"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Might need to trigger this manually or via a CI/CD pipeline after hosted configuration version changes.
# For initial setup, deploy the initial version.
resource "aws_appconfig_deployment" "initial_feature_flags_deployment" {
  application_id          = aws_appconfig_application.feature_flags_app.id
  environment_id          = aws_appconfig_environment.feature_flags_env.environment_id
  configuration_profile_id = aws_appconfig_configuration_profile.feature_flags_profile.configuration_profile_id
  configuration_version   = aws_appconfig_hosted_configuration_version.initial_feature_flags_version.version_number
  deployment_strategy_id  = aws_appconfig_deployment_strategy.feature_flags_strategy.id

  lifecycle {
    ignore_changes = [configuration_version] # stop tf from re-deploying, if just the version changes
  }

  depends_on = [
    aws_appconfig_hosted_configuration_version.initial_feature_flags_version,
    aws_appconfig_deployment_strategy.feature_flags_strategy,
    aws_appconfig_environment.feature_flags_env,
    aws_appconfig_application.feature_flags_app
  ]
}
