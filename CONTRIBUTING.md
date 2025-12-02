# Contributing to Secure Docker CI Pipeline

Thank you for your interest in contributing to this DevSecOps demonstration project!

## Development Setup

1. **Fork and clone the repository**
   ```bash
   git clone https://github.com/your-username/secure-docker-ci-pipeline.git
   cd secure-docker-ci-pipeline
   ```

2. **Install development dependencies**
   ```bash
   cd app
   pip install -r requirements.txt
   ```

3. **Install security tools**
   - Hadolint: `brew install hadolint` (macOS) or download from releases
   - Trivy: `brew install trivy` (macOS)
   - Act: `brew install act` (macOS)

## Development Workflow

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Follow Python PEP 8 style guide
   - Add tests for new functionality
   - Update documentation as needed

3. **Run tests locally**
   ```bash
   cd app
   pytest -v test_app.py
   ```

4. **Lint Dockerfile**
   ```bash
   ./scripts/lint_dockerfile.sh
   ```

5. **Build and test Docker image**
   ```bash
   docker-compose up --build
   ```

6. **Run security scan**
   ```bash
   ./scripts/scan_image.sh secure-docker-ci-pipeline-api
   ```

7. **Test CI pipeline locally**
   ```bash
   act push
   ```

## Pull Request Guidelines

- Ensure all tests pass
- Update README.md if adding new features
- Follow existing code style
- Add meaningful commit messages
- Reference any related issues

## Code Quality Standards

- **Test Coverage**: Maintain or improve test coverage
- **Security**: No critical or high vulnerabilities in dependencies
- **Documentation**: Clear comments and updated docs
- **Dockerfile**: Must pass Hadolint checks

## Questions?

Open an issue for discussion before making major changes.
