# This file is maintained automatically by "terraform init".
# Manual edits may be lost in future updates.

provider "registry.terraform.io/hashicorp/aws" {
  version     = "5.21.0"
  constraints = "~> 5.0"
  hashes = [
    "h1:N8sP6VZjHbtgmaCU6BKPox51UIypWXQRal7JMecEXQw=",
    "zh:1ba1411e4f8c047950db94c236f146d4590790320c68320b4e56082d8746a507",
    "zh:3185e4a34cfcad35dcf11439290a4bd0ad52d462eca2ab5d4940488a2db72833",
    "zh:3c6b901f874b4d9a85301a653d0bd507b052992bd84fc81100f4e5f73b1adab7",
    "zh:45d3fdbbc5804f295576b7155fdca527dedff17a014ed40c215af3bc60c329db",
    "zh:47b64b453d2c373062e47a54f3df33335dc29bce6ddbbf2da9e7be768c560abe",
    "zh:5cdf57ffd465288d9732d14ba13b377a8d389e0ba0ce3ac4773fd6fdfc09d6a1",
    "zh:81ec4c662581a2446c78da7b27d7e0d5c2e4d50925294789ec13661817f4b5a4",
    "zh:9b12af85486a96aedd8d7984b0ff811a4b42e3d88dad1a3fb4c0b580d04fa425",
    "zh:ac248464fd4ce1f020c05f27e3182532a7d1af4b8185a4b4be8b906b30b0ca5a",
    "zh:bbbedc6b6eaffcce0b31b397d607464f0c21c1b9406182163d504d3f392cc68d",
    "zh:c2afc111f9503829ed055e2ae91d873670c57bd16acc1a3246ac3957f6998d4e",
    "zh:cd3c8175b2152848113482da70e5b9c7cb4c951f2046fc0b832715300bd88b97",
    "zh:cf89b0c09d426d489f9477209d4084e64ad1b598036284fa688b41de626b58e6",
    "zh:d9d127637c3b9ff6e2d0a2c30f54bd48ab1de34f725a5df1a6a3d039b021e636",
    "zh:dccca1090e4054d6558218406385fb0421ab4ac3b75e121641973be481a81f01",
  ]
}name: Deploy to Amazon ECS

on:
  push:
    branches: [ main ]
  workflow_dispatch:
    inputs:
      environment:
        description: 'The environment to deploy to'
        required: true
        default: 'production'
        type: choice
        options:
          - prod
          - stage
env:
  AWS_REGION: eu-north-1
  ECS_CLUSTER: express_app_cluster
  CONTAINER_NAME: express_app
  ECS_SERVICE: express_app_service
  ECS_TD: .github/workflows/td.json

jobs:
  test:
    name: Test
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v3
      - name: Setup Node
        uses: actions/setup-node@v3
        with:
          node-version: 20
      - name: Install Dependencies
        run: npm install
      - name: Run tests
        run: npm test

  deploy:
    needs: test
    name: Deploy
    runs-on: ubuntu-latest

    environment: dev

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      - name: Build, tag, and push image to Amazon ECR
        id: build-image
        env:
          ECR_REGISTRY: "${{ secrets.ACCOUNT_ID}}.dkr.ecr.eu-north-1.amazonaws.com"
          ECR_REPOSITORY: "express_app_repo"
          IMAGE_TAG: latest
        run: |
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          echo "image=$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG" >> $GITHUB_OUTPUT

      - name: Fill in the new image ID in the Amazon ECS task definition
        id: task-def-1
        uses: aws-actions/amazon-ecs-render-task-definition@v1
        with:
          task-definition: ${{ env.ECS_TD }}
          container-name: ${{ env.CONTAINER_NAME }}
          image: ${{ steps.build-image.outputs.image }}

      - name: Deploy Amazon ECS task definition
        uses: aws-actions/amazon-ecs-deploy-task-definition@v1
        with:
          task-definition: ${{ steps.task-def-1.outputs.task-definition }}
          service: ${{ env.ECS_SERVICE }}
          cluster: ${{ env.ECS_CLUSTER }}
          wait-for-service-stability: false