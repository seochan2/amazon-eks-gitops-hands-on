resource "aws_cloudwatch_event_rule" "this" {
  name = "${var.prefix}-${var.env}-repo-state-change"
  event_pattern = jsonencode({
    detail-type : [
      "CodeCommit Repository State Change"
    ],
    resources : [
      aws_codecommit_repository.image.arn
    ],
    source : [
      "aws.codecommit"
    ],
    detail : {
      event : [
        "referenceCreated",
        "referenceUpdated"
      ],
      referenceName : [
        "${var.branch_name}"
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "this" {
  rule     = aws_cloudwatch_event_rule.this.id
  arn      = aws_codepipeline.this.arn
  role_arn = aws_iam_role.cloudwatch_events.arn
}

resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "/aws/codebuild/${var.prefix}-${var.env}-project"
  retention_in_days = 30
}

resource "aws_codebuild_project" "this" {
  name          = "${var.prefix}-${var.env}-project"
  build_timeout = "60"
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    packaging = "NONE"
    type      = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }

    environment_variable {
      name  = "ENVIRONMENT"
      value = var.env
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = aws_ecr_repository.this.name
    }

    environment_variable {
      name  = "INFRA_REPO_NAME"
      value = aws_codecommit_repository.k8s.id
    }
  }

  source {
    type            = "CODEPIPELINE"
    git_clone_depth = 0
    buildspec       = file("./modules/ci/buildspec.yml")
  }

  logs_config {
    cloudwatch_logs {
      status     = "ENABLED"
      group_name = aws_cloudwatch_log_group.codebuild.name
    }

    s3_logs {
      status = "DISABLED"
    }
  }
}

resource "aws_codecommit_repository" "image" {
  repository_name = var.codecommit_repository_for_image
}

resource "aws_codecommit_repository" "k8s" {
  repository_name = var.codecommit_repository_for_k8s
}

resource "aws_codepipeline" "this" {
  name     = "${var.prefix}-${var.env}-pipeline"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.artifacts_store.id
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      provider = "CodeCommit"
      category = "Source"
      configuration = {
        BranchName           = var.branch_name
        PollForSourceChanges = "false"
        RepositoryName       = aws_codecommit_repository.image.id
      }
      name             = aws_codecommit_repository.image.id
      owner            = "AWS"
      version          = "1"
      output_artifacts = ["source_output"]
      role_arn         = aws_iam_role.codepipeline_codecommit.arn
    }
  }

  stage {
    name = "Build"
    action {
      category = "Build"
      configuration = {
        ProjectName = aws_codebuild_project.this.name
      }
      input_artifacts = ["source_output"]
      name            = aws_codebuild_project.this.name
      provider        = "CodeBuild"
      owner           = "AWS"
      version         = "1"
      role_arn        = aws_iam_role.codepipeline_codebuild.arn
    }
  }
}

resource "aws_ecr_repository" "this" {
  name                 = var.ecr_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_iam_role" "cloudwatch_events" {
  name = "${var.prefix}-${var.env}-events"
  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Action : "sts:AssumeRole",
        Principal : {
          Service : "events.amazonaws.com"
        },
        Effect : "Allow",
        Sid : ""
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudwatch_events_codepipeline" {
  name = "${var.prefix}-${var.env}-events-codepipeline"
  role = aws_iam_role.cloudwatch_events.id
  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Action : [
          "codepipeline:StartPipelineExecution"
        ],
        Resource : [
          aws_codepipeline.this.arn
        ],
        Effect : "Allow"
      }
    ]
  })
}

resource "aws_iam_role" "codepipeline" {
  name = "${var.prefix}-${var.env}-codepipeline"
  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Action : "sts:AssumeRole",
        Principal : {
          Service : "codepipeline.amazonaws.com"
        },
        Effect : "Allow",
        Sid : ""
      }
    ]
  })
}

resource "aws_iam_role_policy" "codepipeline" {
  name = "${var.prefix}-${var.env}-codepipeline"
  role = aws_iam_role.codepipeline.id

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Action : "sts:AssumeRole",
        Resource : aws_iam_role.codepipeline_codecommit.arn,
        Effect : "Allow"
      },
      {
        Action : "sts:AssumeRole",
        Resource : aws_iam_role.codepipeline_codebuild.arn,
        Effect : "Allow"
      }
    ]
  })
}

resource "aws_iam_role" "codepipeline_codecommit" {
  name = "${var.prefix}-${var.env}-codepipeline-codecommit"
  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Action : "sts:AssumeRole",
        Principal : {
          AWS : aws_iam_role.codepipeline.arn
        },
        Effect : "Allow",
        Sid : ""
      }
    ]
  })
}

resource "aws_iam_role_policy" "for_repository" {
  name = "${var.prefix}-${var.env}-repository"
  role = aws_iam_role.codepipeline_codecommit.id

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Action : [
          "codecommit:GetBranch",
          "codecommit:GetCommit",
          "codecommit:UploadArchive",
          "codecommit:GetUploadArchiveStatus",
          "codecommit:CancelUploadArchive"
        ],
        Resource : aws_codecommit_repository.image.arn,
        Effect : "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy" "for_artifacts_store" {
  name = "${var.prefix}-${var.env}-artifacts-store"
  role = aws_iam_role.codepipeline_codecommit.id

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Action : [
          "s3:Get*",
          "s3:Put*",
        ],
        Resource : "${aws_s3_bucket.artifacts_store.arn}/*",
        Effect : "Allow"
      },
      {
        Action : [
          "s3:ListBucket",
        ],
        Resource : aws_s3_bucket.artifacts_store.arn,
        Effect : "Allow"
      }
    ]
  })
}

resource "aws_iam_role" "codepipeline_codebuild" {
  name = "${var.prefix}-${var.env}-codepipeline-codebuild"
  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Action : "sts:AssumeRole",
        Principal : {
          AWS : aws_iam_role.codepipeline.arn
        },
        Effect : "Allow",
        Sid : ""
      }
    ]
  })
}

resource "aws_iam_role_policy" "for_build" {
  name = "${var.prefix}-${var.env}-build"
  role = aws_iam_role.codepipeline_codebuild.id

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Action : [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild",
          "codebuild:StopBuild"
        ],
        Resource : [
          aws_codebuild_project.this.arn,
        ],
        Effect : "Allow"
      },
      {
        Action : [
          "logs:CreateLogGroup"
        ],
        Resource : "*",
        Effect : "Allow"
      }
    ]
  })
}

resource "aws_iam_role" "codebuild" {
  name = "${var.prefix}-${var.env}-codebuild"
  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Action : "sts:AssumeRole",
        Principal : {
          Service : "codebuild.amazonaws.com"
        },
        Effect : "Allow",
        Sid : ""
      }
    ]
  })
}

resource "aws_iam_role_policy" "codebuild" {
  name = "${var.prefix}-${var.env}-codebuild"
  role = aws_iam_role.codebuild.id
  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Action : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource : "*",
        Effect : "Allow"
      },
      {
        Action : [
          "logs:CreateLogGroup"
        ],
        Resource : "*",
        Effect : "Allow"
      },
      {
        "Action" : [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:GetAuthorizationToken",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ],
        "Resource" : "*",
        "Effect" : "Allow"
      },
      {
        Action : [
          "codecommit:GitPull",
          "codecommit:GitPush",
          "codecommit:CreatePullRequest",
          "codecommit:MergePullRequestByFastForward",
          "codecommit:MergePullRequestBySquash",
          "codecommit:MergePullRequestByThreeWay",
          "codecommit:DeleteBranch"
        ],
        Resource : "*",
        Effect : "Allow"
      }
    ]
  })
}

resource "aws_iam_user" "argocd_sync" {
  name = "${var.prefix}-${var.env}-argocd-sync"
}

resource "aws_iam_user_policy" "for_argocd_sync" {
  name = "${var.prefix}-${var.env}-argocd-sync"
  user = aws_iam_user.argocd_sync.name

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Action : [
          "codecommit:GitPull"
        ],
        Resource : aws_codecommit_repository.k8s.arn
      }
    ]
  })
}

resource "aws_iam_service_specific_credential" "argocd_sync" {
  service_name = "codecommit.amazonaws.com"
  user_name    = aws_iam_user.argocd_sync.name
}

resource "aws_s3_bucket" "artifacts_store" {
  bucket        = "${var.prefix}-${var.env}-codepipeline-${data.aws_region.current.name}-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "artifacts_store" {
  bucket = aws_s3_bucket.artifacts_store.id
  
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "artifacts_store" {
  bucket = aws_s3_bucket.artifacts_store.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "artifacts_store" {
 depends_on = [
    aws_s3_bucket_ownership_controls.artifacts_store,
    aws_s3_bucket_public_access_block.artifacts_store,
  ]

  bucket = aws_s3_bucket.artifacts_store.id
  acl    = "private"
}

resource "aws_s3_bucket_policy" "artifacts_store" {
  bucket = aws_s3_bucket.artifacts_store.id
  policy = jsonencode({
    Version : "2012-10-17",
    Id : "ArtifactsStorePolicy",
    Statement : [
      {
        Sid : "CodePipelineBucketPolicy",
        Effect : "Allow",
        Principal : {
          AWS : [
            aws_iam_role.codepipeline_codecommit.arn,
            aws_iam_role.codebuild.arn,
        ] },
        Action : [
          "s3:Get*",
          "s3:Put*"
        ],
        Resource : "${aws_s3_bucket.artifacts_store.arn}/*",
      },
      {
        Sid : "CodePipelineBucketListPolicy",
        Effect : "Allow",
        Principal : {
          AWS : [
            aws_iam_role.codepipeline_codecommit.arn,
            aws_iam_role.codebuild.arn,
        ] },
        Action : "s3:ListBucket",
        Resource : aws_s3_bucket.artifacts_store.arn,
      }
    ]
  })
}
