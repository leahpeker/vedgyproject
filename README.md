# VedgyProject 🌱

**Open-source vegan housing platform - contribute to make it better for everyone!**

VedgyProject is a community-driven platform connecting vegan renters with vegan-friendly housing. This is the official repository - contribute code, report bugs, and help build the future of vegan housing together.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.13+](https://img.shields.io/badge/python-3.13+-blue.svg)](https://www.python.org/downloads/)
[![Django](https://img.shields.io/badge/Django-5.0+-green.svg)](https://www.djangoproject.com/)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B.svg)](https://flutter.dev/)

## 🌟 About VedgyProject

**Live site**: [vedgyproject.up.railway.app](https://vedgyproject.up.railway.app/)

VedgyProject helps vegans find housing in vegan-friendly households. Whether you're looking for a fully vegan house or just a welcoming environment, we connect plant-based renters with like-minded hosts.

### 🏠 Features

- Browse vegan-friendly housing listings across major cities
- Filter by price, location, room type, and household vegan status
- Create listings with photo uploads and detailed descriptions
- Sliding-scale payment model ($3-$15) based on ability to pay
- User dashboard to manage listings
- 30-day listing duration with renewal options

### 💰 Community-Focused Pricing

- **$3**: Students and low-income users
- **$8**: Median income users
- **$15**: High-income users supporting the platform

## 🛠️ Tech Stack

- **Backend**: Django 5.2 (API-only via Django Ninja), PostgreSQL
- **Frontend**: Flutter Web (Riverpod + GoRouter + Dio)
- **Storage**: Backblaze B2 for photo uploads
- **Hosting**: Railway
- **Payment**: Manual Venmo processing

## 🤝 Contributing to VedgyProject

**We need your help to make VedgyProject better!** This is an open-source project built by and for the vegan community.

### Prerequisites

- [uv](https://docs.astral.sh/uv/) (Python package manager)
- [Docker](https://docs.docker.com/get-docker/) (for local PostgreSQL)
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (for the frontend — `make install` will install via Homebrew on macOS if missing)

### 🚀 Getting Started for Contributors

1. **Fork this repository** (for contributing back to the main project)

2. **Clone your fork locally**

   ```bash
   git clone https://github.com/YOUR-USERNAME/vedgyproject.git
   cd vedgyproject
   ```

3. **Set up environment config**

   ```bash
   cp .env.example .env
   ```

   The defaults in `.env.example` are pre-configured to work with the local Docker PostgreSQL container.

4. **Start local PostgreSQL**

   ```bash
   make db-start
   ```

5. **Install dependencies and run migrations**

   ```bash
   make install
   make migrate
   ```

   `make install` installs both Python (via uv) and Flutter (via `flutter pub get`) dependencies.

6. **Run locally**

   ```bash
   make dev
   ```

   This starts both the Django API server (http://localhost:8000) and the Flutter web app (http://localhost:3000) concurrently. Press Ctrl-C to stop both.

   You can also run them separately:

   ```bash
   make run              # Django API only (localhost:8000)
   make frontend-run     # Flutter web only (localhost:3000)
   ```

7. **Run all checks**

   ```bash
   make ci
   ```

   Runs lint → Django checks → backend tests → frontend lint → frontend tests. All must pass before committing.

8. **Create a feature branch and submit a PR**

   ```bash
   git checkout -b feature/your-feature-name
   ```

   When finished, open a Pull Request to the `development` branch.

### 🔧 Make Commands

**Backend:**

| Command | Description |
|---------|-------------|
| `make install` | Install all dependencies (Python + Flutter) |
| `make run` | Run Django dev server (localhost:8000) |
| `make test` | Run Django pytest suite |
| `make lint` | Run autoflake + isort + black |
| `make check` | Run Django system checks |
| `make migrate` | Run makemigrations + migrate |
| `make createsuperuser` | Create Django admin user |
| `make seed` | Seed DB with test users + listings |
| `make seed-reset` | Delete and re-create all seed data |
| `make db-start` | Start local PostgreSQL (Docker) |
| `make db-stop` | Stop local PostgreSQL (Docker) |

**Frontend:**

| Command | Description |
|---------|-------------|
| `make frontend-install` | Install Flutter dependencies (`flutter pub get`) |
| `make frontend-run` | Run Flutter web dev server (localhost:3000) |
| `make frontend-build` | Build Flutter web release (requires `API_URL` env var) |
| `make frontend-codegen` | Regenerate freezed/riverpod/json code |
| `make frontend-lint` | Run dart format check + dart analyze |
| `make frontend-format` | Auto-format Dart files |
| `make frontend-fix` | Auto-apply dart fix suggestions |
| `make frontend-test` | Run Flutter test suite |

**Combined:**

| Command | Description |
|---------|-------------|
| `make dev` | Run Django + Flutter concurrently |
| `make ci` | Run all pre-commit checks (lint, check, test, frontend-lint, frontend-test) |

### 🐛 Ways to Contribute

- **Report bugs** - Found something broken? Open an issue!
- **Suggest features** - Ideas for improvements? We want to hear them!
- **Fix bugs** - Check our [Issues](https://github.com/leahpeker/vedgyproject/issues) for bugs to fix
- **Add features** - Pick up a feature request or propose your own
- **Improve UI/UX** - Help make the site more beautiful and usable
- **Write tests** - Help us maintain code quality
- **Update documentation** - Keep docs current and helpful

### 📋 Current Priorities

**High Priority:**

- Enhanced mobile experience
- Search improvements

**Medium Priority:**

- OAuth integration (Google, GitHub)
- User profiles and messaging
- On-platform messaging system (instead of direct email contact)
- Email notifications
- Saved searches

**Long-term Goals:**

- Native mobile apps
- Advanced search and filtering

See our [Issues](https://github.com/leahpeker/vedgyproject/issues) for specific tasks!

### 🔧 Development Guidelines

- **Python style**: Follow PEP 8
- **Commits**: Write clear, descriptive commit messages
- **Testing**: Test your changes locally first
- **PRs**: Reference any related issues in your PR description
- **Community**: Be respectful and inclusive

### 🎯 How to Submit Changes

1. Create a new branch from development: `git checkout development && git checkout -b feature/your-feature-name`
2. Make your changes and test locally
3. Commit with a clear message: `git commit -m "Add feature: description"`
4. Push to your fork: `git push origin feature/your-feature-name`
5. **Open a Pull Request to the `development` branch** (not main)

## 📄 License

MIT License - see [LICENSE](LICENSE) file.

**tl;dr**: You can use, modify, and distribute this code, but contributions back to this project help everyone in the vegan community!

## 🌱 Mission

VedgyProject exists to support the vegan community by making it easier to find housing in vegan-friendly environments.

Our sliding-scale model ensures economic barriers don't prevent access, and our open-source model lets the community shape the platform's future.

## 💚 Support the Project

Love what we're building? Help keep VedgyProject free and community-focused!

**📱 Quick Donations:**

- **Venmo**: [@leah-peker](https://venmo.com/u/leah-peker)
- **CashApp**: [$leahpeker](https://cash.app/$leahpeker)

Your support helps with:

- Server costs and infrastructure
- New feature development
- Keeping the platform ad-free
- Supporting the vegan community

_Every contribution, no matter the size, makes a difference! 🌱_

## 💬 Get Involved

- 🐛 **Issues**: Report bugs or request features
- 💡 **Discussions**: Share ideas and ask questions
- 📧 **Contact**: Questions? Email [leahpeker@gmail.com](mailto:leahpeker@gmail.com)

---

**Built with 🌱 by the vegan community, for the vegan community.**

_Want to see your contribution on a platform used by vegans worldwide? Start contributing today!_
