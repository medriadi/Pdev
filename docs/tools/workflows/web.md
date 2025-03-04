# Web Development Workflow

This guide explains how to use PDev's tools for web development.

## Quick Start

1. Create a new project:
```bash
# Create project directory
mkdir -p ~/dev/projects/my-web-app
cd ~/dev/projects/my-web-app

# Initialize with your preferred framework
# React
npx create-react-app .

# OR Vue
npm init vue@latest

# OR Next.js
npx create-next-app@latest
```

2. Open in VS Code with PDev's configuration:
```bash
code .
```

## Development Environment

### Essential Tools

PDev automatically sets up:

- Node.js and npm/yarn
- Git for version control
- VS Code with web development extensions
- Docker for containerization
- Database systems (PostgreSQL/MongoDB)
- API testing tools (Postman/Insomnia)

### VS Code Extensions

Automatically installed extensions:
- ESLint for linting
- Prettier for formatting
- Live Server for static files
- GitLens for version control
- Docker for container management
- REST Client for API testing

## Development Workflow

### 1. Project Setup

```bash
# Create development database
pdev db create my-web-app-dev

# Set up environment
cp .env.example .env
pdev env setup web

# Install dependencies
npm install

# Start development server
npm run dev
```

### 2. Development Cycle

1. Write code with live reload
2. Auto-format on save (Prettier)
3. Real-time linting (ESLint)
4. Git integration in editor
5. Integrated terminal for commands
6. Docker containers for services

### 3. Database Management

```bash
# Start database
pdev db start

# Run migrations
npm run migrate

# Access database UI
pdev db ui
```

### 4. API Development

1. Test APIs with integrated REST Client
2. Auto-generate API documentation
3. Mock endpoints for development
4. Monitor API requests

### 5. Testing

```bash
# Run tests with watch mode
npm test

# Run E2E tests
npm run test:e2e

# Check coverage
npm run test:coverage
```

### 6. Deployment

```bash
# Build production version
npm run build

# Deploy to development
pdev deploy dev

# Deploy to staging
pdev deploy staging
```

## Docker Integration

### Development Containers

```bash
# Start development environment
docker compose up -d

# View logs
docker compose logs -f

# Stop environment
docker compose down
```

### Production Build

```bash
# Build production image
docker build -t my-web-app:prod .

# Test production build
docker run -p 3000:3000 my-web-app:prod
```

## Database Management

### Local Development

```bash
# Create database
pdev db create my-web-app-dev

# Run migrations
pdev db migrate

# Seed data
pdev db seed
```

### Database GUI

Access database management UI:
```bash
pdev db ui
```

## Debugging

### Browser DevTools

1. Open Chrome DevTools (F12)
2. Use VS Code debugger integration
3. Debug running containers

### Node.js Debugging

1. Set breakpoints in VS Code
2. Use debug configurations
3. Inspect variables and state

## Performance Optimization

### Code Analysis

```bash
# Run performance audit
npm run analyze

# Check bundle size
npm run build:analyze
```

### Monitoring

```bash
# Monitor development server
pdev monitor dev

# Check API performance
pdev monitor api
```

## Best Practices

### Code Quality

- Use TypeScript for type safety
- Follow ESLint rules
- Format with Prettier
- Write tests for components
- Document with JSDoc

### Security

- Keep dependencies updated
- Use security linting rules
- Follow OWASP guidelines
- Implement proper authentication
- Validate all inputs

### Performance

- Optimize images and assets
- Use code splitting
- Implement caching
- Monitor bundle size
- Profile render performance

## Troubleshooting

### Common Issues

1. Node Version Mismatch
```bash
pdev node use
```

2. Database Connection Issues
```bash
pdev db doctor
```

3. Docker Problems
```bash
pdev docker reset
```

## CI/CD Integration

### GitHub Actions

PDev provides workflow templates:
```bash
pdev ci setup web
```

### Quality Checks

Automated checks for:
- Linting
- Testing
- Type checking
- Security scanning
- Performance metrics

## Additional Resources

- [Frontend Best Practices](frontend-best-practices.md)
- [API Development Guide](api-development.md)
- [Testing Strategies](testing-strategies.md)
- [Deployment Guide](deployment.md)
- [Performance Tips](performance-tips.md)