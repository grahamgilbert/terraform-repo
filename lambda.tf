resource "aws_iam_role" "iam_for_redirect_lambda" {
  name = "iam_for_redirect_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com",
          "edgelambda.amazonaws.com"
        ]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "archive_file" "redirect_lambda_zip" {
  type = "zip"

  output_path = "redirect_lambda.zip"
  source_file = "${path.module}/lambda_code/redirect.js"
}

resource "aws_lambda_function" "redirect_lambda" {
  filename         = "redirect_lambda.zip"
  function_name    = "redirect_lambda"
  role             = "${aws_iam_role.iam_for_redirect_lambda.arn}"
  handler          = "redirect.handler"
  source_code_hash = "${data.archive_file.redirect_lambda_zip.output_base64sha256}"
  runtime          = "nodejs10.x"
  publish          = true
}

resource "aws_iam_role" "iam_for_hsts_lambda" {
  name = "iam_for_hsts_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com",
          "edgelambda.amazonaws.com"
        ]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "archive_file" "hsts_lambda_zip" {
  type = "zip"

  output_path = "hsts_lambda.zip"
  source_file = "${path.module}/lambda_code/hsts.js"
}

resource "aws_lambda_function" "hsts_lambda" {
  filename         = "hsts_lambda.zip"
  function_name    = "hsts_lambda"
  role             = "${aws_iam_role.iam_for_hsts_lambda.arn}"
  handler          = "hsts.handler"
  source_code_hash = "${data.archive_file.hsts_lambda_zip.output_base64sha256}"
  runtime          = "nodejs10.x"
  publish          = true
}
