# VegListings 🌱

A simple vegan-friendly housing platform built with Flask, HTMX, and Tailwind CSS.

## Features

- Browse vegan-friendly housing listings
- Real-time filtering by rental type, room type, price range, and location
- Create new listings
- Responsive design with minimal styling
- HTMX for dynamic interactions without page reloads

## Tech Stack

- **Backend**: Flask, SQLAlchemy
- **Frontend**: HTMX, Tailwind CSS
- **Database**: SQLite
- **Styling**: Tailwind CSS (CDN)

## Setup

1. Clone the repository
2. Create and activate virtual environment:
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   ```
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Run the application:
   ```bash
   python app.py
   ```
5. Visit http://127.0.0.1:5000

## Roadmap

- [ ] User authentication (email/password + OAuth)
- [ ] Payment integration for listings
- [ ] User dashboard
- [ ] Contact system with paid access
- [ ] User profiles

## Contributing

This is a simple project for learning purposes. Feel free to fork and experiment!