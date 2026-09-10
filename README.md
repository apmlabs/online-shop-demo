# 🛒 Online Shop Demo on AWS EKS: Your Cloud-Native E-Commerce Platform

Welcome to the future of e-commerce! Deploy a complete microservices-based online shop and experience the power of distributed monitoring across 11 interconnected services. 🚀

> **🎯 Current Status**: Check [AmazonQ.md](./AmazonQ.md) for live deployment info!

## 🎭 Meet Online Shop Demo: The Microservices E-Commerce Showcase

Imagine a bustling online marketplace with multiple specialized departments working seamlessly together. That's the Online Shop Demo! This isn't just another demo app - it's a **complete e-commerce ecosystem** that showcases:

- 🏗️ **Cloud-native microservices architecture** with 11 specialized services
- 🔄 **Real-world e-commerce workflows** - browse, cart, checkout, payment
- 💥 **Kubernetes-native deployment** on AWS EKS with auto-scaling
- 🌐 **Modern web interface** with responsive design
- 🤖 **Built-in load generation** - realistic customer behavior simulation
- 📊 **Full observability** with Dynatrace monitoring

## 🎒 What You'll Need for This Journey

- 🔑 AWS account with EKS superpowers
- 🧠 Basic knowledge of Kubernetes and AWS EKS
- 🐳 Understanding of containerized microservices architectures

## 💪 EKS Cluster Power Requirements

Your e-commerce empire needs solid Kubernetes infrastructure! Here's what works:

- **🏆 Proven Champion**: 3 x t3a.medium nodes (2 vCPU, 4GB RAM each) - handles the shopping load perfectly!
- **⚡ Kubernetes Version**: 1.31 or earlier (AL2_x86_64) or 1.33+ (AL2023_x86_64_STANDARD)
- **💾 Storage**: 20GB per node
- **🌐 Networking**: Default VPC with public/private subnets

> **💡 Pro Tip**: t3a.medium nodes provide the perfect balance of cost and performance for this microservices platform!

## 🏗️ Your E-Commerce Architecture (The Shopping Empire)

| Service | Description | Role | Resources |
|---------|-------------|------|-----------|
| Frontend | Web UI & customer interface | 🏪 Storefront | 100m CPU, 64Mi RAM |
| Cart Service | Shopping cart management | 🛒 Cart | 200m CPU, 64Mi RAM |
| Product Catalog | Product information & search | 📦 Catalog | 100m CPU, 64Mi RAM |
| Checkout Service | Order processing engine | 💳 Checkout | 100m CPU, 64Mi RAM |
| Payment Service | Payment processing | 💰 Payments | 100m CPU, 64Mi RAM |
| Shipping Service | Delivery management | 🚚 Shipping | 100m CPU, 64Mi RAM |
| Email Service | Customer notifications | 📧 Notifications | 100m CPU, 64Mi RAM |
| Currency Service | Multi-currency support | 💱 Currency | 100m CPU, 64Mi RAM |
| Recommendation | AI-powered suggestions | 🎯 AI Engine | 200m CPU, 220Mi RAM |
| Ad Service | Advertisement platform | 📢 Marketing | 200m CPU, 180Mi RAM |
| Redis | Session & cart storage | 🗄️ Cache | 70m CPU, 200Mi RAM |
| Load Generator | Synthetic customers | 🤖 Traffic | 500m CPU, 256Mi RAM |

**Total Resources**: ~1.4 vCPU requests, ~1.2GB memory requests

## 🚀 Let's Get This E-Commerce Platform Running!

### 1. 🏗️ Create EKS Service Role
```bash
# Check if role exists first
if ! aws iam get-role --region us-east-2 --role-name eks-cluster-role 2>/dev/null; then
  # Create trust policy
  cat > eks-service-role-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  # Create role
  aws iam create-role --region us-east-2 --role-name eks-cluster-role --assume-role-policy-document file://eks-service-role-trust-policy.json
fi

# Attach policy (idempotent)
aws iam attach-role-policy --region us-east-2 --role-name eks-cluster-role --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
```

### 2. 🎯 Create Your EKS Shopping Cluster
```bash
# Get VPC and subnets
VPC_ID=$(aws ec2 describe-vpcs --region us-east-2 --filters "Name=is-default,Values=true" --query "Vpcs[0].VpcId" --output text)
SUBNETS=$(aws ec2 describe-subnets --region us-east-2 --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[*].SubnetId" --output text | tr '\t' ' ')

# Determine unique cluster name
CLUSTER_NAME="online-shop-demo-mcp"
VERSION=1
while aws eks describe-cluster --region us-east-2 --name $CLUSTER_NAME 2>/dev/null; do
  VERSION=$((VERSION + 1))
  CLUSTER_NAME="online-shop-demo-mcp-v$VERSION"
done
echo "Using cluster name: $CLUSTER_NAME"

# Create cluster
aws eks create-cluster --region us-east-2 --name $CLUSTER_NAME --version 1.31 --role-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/eks-cluster-role --resources-vpc-config subnetIds=$SUBNETS,endpointPrivateAccess=true,endpointPublicAccess=true

# Wait for cluster to be active
aws eks wait cluster-active --region us-east-2 --name $CLUSTER_NAME
```

### 3. 🔧 Create Node Group Role
```bash
# Check if nodegroup role exists first
if ! aws iam get-role --region us-east-2 --role-name eks-nodegroup-role 2>/dev/null; then
  # Create nodegroup trust policy
  cat > nodegroup-role-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  # Create role
  aws iam create-role --region us-east-2 --role-name eks-nodegroup-role --assume-role-policy-document file://nodegroup-role-trust-policy.json
fi

# Attach policies (idempotent)
aws iam attach-role-policy --region us-east-2 --role-name eks-nodegroup-role --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
aws iam attach-role-policy --region us-east-2 --role-name eks-nodegroup-role --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
aws iam attach-role-policy --region us-east-2 --role-name eks-nodegroup-role --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
```

### 4. 🚀 Launch Your Shopping Node Group
```bash
# Create nodegroup (cluster must be ACTIVE first)
aws eks create-nodegroup --region us-east-2 --cluster-name $CLUSTER_NAME --nodegroup-name $CLUSTER_NAME-nodes --node-role arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/eks-nodegroup-role --subnets $SUBNETS --instance-types t3a.medium --scaling-config minSize=3,maxSize=6,desiredSize=3 --disk-size 20 --ami-type AL2023_x86_64_STANDARD --capacity-type ON_DEMAND

# Wait for nodegroup to be active
aws eks wait nodegroup-active --region us-east-2 --cluster-name $CLUSTER_NAME --nodegroup-name $CLUSTER_NAME-nodes
```

### 5. 🔌 Connect kubectl to Your Shopping Empire
```bash
aws eks update-kubeconfig --region us-east-2 --name $CLUSTER_NAME
```

### 6. 👁️ Install Dynatrace Operator (The All-Seeing Shopping Monitor)

**🚨 Critical**: Install Dynatrace operator BEFORE deploying microservices for complete visibility!

```bash
kubectl create namespace dynatrace
kubectl apply -f https://github.com/Dynatrace/dynatrace-operator/releases/latest/download/kubernetes.yaml
kubectl -n dynatrace wait --for=condition=ready pod --selector=app.kubernetes.io/name=dynatrace-operator --timeout=300s
```

### 7. 🔧 Configure Dynatrace Monitoring
```bash
# Apply secrets first (contains your Dynatrace credentials)
kubectl apply -f secrets.yaml

# Then apply DynaKube configuration
kubectl apply -f dynakube.yaml
```

### 8. 🛒 Deploy Your Online Shop Empire!
```bash
kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/main/release/kubernetes-manifests.yaml
```

### 9. ✅ Verify Your Shopping Platform is Live
```bash
kubectl get pods --all-namespaces
kubectl get services
```

All pods should show "Running" status. Your e-commerce platform is ready for customers! 🎉

## 🎉 Access Your Shopping Empire

Once deployed, explore your e-commerce platform:

```bash
# Get the frontend service URL
kubectl get service frontend-external
```

- **🌟 Online Shop**: `http://EXTERNAL_IP:80` (from frontend-external service)
- **🔧 All Services**: Check with `kubectl get services`

## 💥 Built-in E-Commerce Scenarios

Your shopping platform includes realistic scenarios for demonstration:

- 🛒 **Product Browsing**: Customers exploring your catalog
- 💳 **Shopping Cart**: Adding and removing items
- 🔍 **Product Search**: Finding specific products
- 💰 **Checkout Process**: Complete purchase workflows
- 📧 **Email Notifications**: Order confirmations
- 🚚 **Shipping Tracking**: Delivery management
- 🎯 **Recommendations**: AI-powered product suggestions
- 📢 **Advertisements**: Targeted marketing campaigns

## 🛠️ Shopping Platform Management Commands

### Check your shopping services
```bash
kubectl get pods
kubectl logs -f deployment/frontend
```

### Scale your shopping capacity
```bash
kubectl scale deployment frontend --replicas=3
```

### Update your shopping platform
```bash
kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/main/release/kubernetes-manifests.yaml
```

### Monitor shopping traffic
```bash
kubectl top pods
kubectl top nodes
```

## 🔧 Troubleshooting Your Shopping Platform

### Check if customers can reach your shop
```bash
kubectl get services
kubectl describe service frontend-external
```

### Inspect your shopping services
```bash
kubectl get pods --all-namespaces
kubectl describe pod POD_NAME
```

### Read service logs
```bash
kubectl logs deployment/frontend
kubectl logs deployment/cartservice
```

### Check cluster health
```bash
kubectl get nodes
aws eks describe-cluster --region us-east-2 --name $CLUSTER_NAME
```

## 💰 Cost Optimization for Your Shopping Business

- Use **t3a.medium nodes** for optimal cost/performance balance
- **Scale down node group** when shop is closed to save costs
- Consider **Spot instances** for development environments
- Monitor **CloudWatch costs** for EKS cluster expenses
- Use **Horizontal Pod Autoscaler** for automatic scaling

## 🔒 Shopping Security Notes

- EKS cluster uses **IAM roles** for secure access
- **Network policies** can restrict inter-service communication
- Consider **AWS Load Balancer Controller** for production
- Monitor **CloudWatch** for cluster security events
- Set up **cost alerts** to prevent surprise bills

## 🎯 Next Steps for Your Shopping Empire

1. Configure Dynatrace monitoring dashboards
2. Set up business event capture for purchase analytics
3. Implement custom metrics for shopping behavior
4. Configure alerting for service failures
5. Explore Kubernetes autoscaling features

## 🧹 Cleanup Your Shopping Infrastructure

### ⚠️ CRITICAL: LoadBalancer Cleanup Warning
**Kubernetes LoadBalancer services create AWS ELBs that persist after cluster deletion and continue billing!**

**Always delete LoadBalancer services FIRST:**
```bash
kubectl delete service frontend-external
```

### Option 1: Close Shop Temporarily (Preserve for Later)

For temporary shutdown while keeping all your shopping configuration:

```bash
# Scale down to save costs (preserves all configuration)
aws eks update-nodegroup-config --region us-east-2 --cluster-name $CLUSTER_NAME --nodegroup-name $CLUSTER_NAME-nodes --scaling-config minSize=0,maxSize=6,desiredSize=0

# Reopen for business later
aws eks update-nodegroup-config --region us-east-2 --cluster-name $CLUSTER_NAME --nodegroup-name $CLUSTER_NAME-nodes --scaling-config minSize=3,maxSize=6,desiredSize=3
```

**Benefits**: No redeployment needed, faster reopening, keeps all Kubernetes configuration.

### Option 2: Permanent Shopping Platform Closure

When you're done with the shopping demo permanently:

1. **Delete microservices**: `kubectl delete -f https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/main/release/kubernetes-manifests.yaml`
2. **Delete Dynatrace**: `kubectl delete -f https://github.com/Dynatrace/dynatrace-operator/releases/latest/download/kubernetes.yaml`
3. **Delete node group**: `aws eks delete-nodegroup --region us-east-2 --cluster-name $CLUSTER_NAME --nodegroup-name $CLUSTER_NAME-nodes`
4. **Delete cluster**: `aws eks delete-cluster --region us-east-2 --name $CLUSTER_NAME`
5. **Clean up IAM roles** (if no other EKS clusters need them)

Always scale down or delete resources to stop shopping expenses immediately! 💸

---

**🛒 Repository**: https://github.com/GoogleCloudPlatform/microservices-demo  
**📚 Architecture**: Cloud-native microservices e-commerce platform  
**🎯 Use Case**: Complete online shopping application for Kubernetes demonstrations  
**📊 Context**: See [AmazonQ.md](./AmazonQ.md) for current deployment status


## Codex development

Start Codex in this directory. [AGENTS.md](AGENTS.md) defines the project role; [PROGRESS.md](PROGRESS.md) is the current handover and work log; [.codex/knowledge/INDEX.md](.codex/knowledge/INDEX.md) indexes detailed inherited knowledge. Original history and Kiro skills remain preserved.
