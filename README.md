# VedgyProject 🌱

**Open-source vegan housing platform - contribute to make it better for everyone!**

VedgyProject is a community-driven platform connecting vegan renters with vegan-friendly housing. This is the official repository - contribute code, report bugs, and help build the future of vegan housing together.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.13+](https://img.shields.io/badge/python-3.13+-blue.svg)](https://www.python.org/downloads/)
[![Django](https://img.shields.io/badge/Django-5.0+-green.svg)](https://www.djangoproject.com/)

## 🌟 About VedgyProject

**Live site**: [veglistings.up.railway.app](https://veglistings.up.railway.app/)

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

- **Backend**: Django 5.0, PostgreSQL
- **Frontend**: HTMX, Alpine.js, Tailwind CSS
- **Storage**: Backblaze B2 for photo uploads
- **Hosting**: Railway
- **Payment**: Manual Venmo processing

## 🤝 Contributing to VedgyProject

**We need your help to make VedgyProject better!** This is an open-source project built by and for the vegan community.

### 🚀 Getting Started for Contributors

1. **Fork this repository** (for contributing back to the main project)

2. **Clone your fork locally**

   ```bash
   git clone https://github.com/YOUR-USERNAME/veglistings.git
   cd veglistings
   ```

3. **Set up development environment**

   ```bash
   python3 -m venv venv
   source venv/bin/activate  # Windows: venv\Scripts\activate
   pip install -r backend/requirements-django.txt
   ```

4. **Run database migrations**

   ```bash
   cd backend
   python manage.py migrate
   ```

5. **Create a feature branch from development**

   ```bash
   git checkout development
   git checkout -b feature/your-feature-name
   ```

6. **Run locally**

   ```bash
   # From project root
   python run-django.py

   # Or from backend directory
   cd backend
   python manage.py runserver
   ```

   Visit http://127.0.0.1:8000

   _No additional configuration needed for local development! Uses SQLite by default._

7. **Run tests**

   ```bash
   cd backend
   pytest
   ```

8. **Make your changes and submit a PR to the development branch!**

### 🐛 Ways to Contribute

- **Report bugs** - Found something broken? Open an issue!
- **Suggest features** - Ideas for improvements? We want to hear them!
- **Fix bugs** - Check our [Issues](https://github.com/leahpeker/veglistings/issues) for bugs to fix
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

- Separate REST API and frontend
- Modern React/Vue.js frontend option
- Native mobile apps
- Advanced search and filtering

See our [Issues](https://github.com/leahpeker/veglistings/issues) for specific tasks!

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
