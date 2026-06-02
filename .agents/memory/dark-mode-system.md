---
name: Dark mode system
description: How dark mode is implemented — ThemeContext, CSS vars, class toggling, and component conventions.
---

# Dark Mode System

## Mechanism
- `ThemeContext` at `vakil-main/frontend/src/contexts/ThemeContext.js`
- Persists to `localStorage` key `gb-theme` (`'dark'` | `'light'`)
- On mount / change: adds/removes `.dark` class on `document.documentElement`
- `useTheme()` hook exports `{ isDark, toggleTheme }`

## CSS Variables
- `:root` = light (wine `#7C1D2B`, bg `#FFFDF7`, fg `#171717`)
- `.dark` = dark (gold `#D4AF37`, bg `#0d0d0d`, fg `#e8e8e8`)
- Key var names: `--theme-bg`, `--theme-fg`, `--theme-primary`, `--theme-gold`, `--theme-border`, etc.

## App structure
- `ThemeProvider` wraps everything inside `<BrowserRouter>` in `App.js`
- Pattern overlay opacity: `isDark ? 0.04 : 0.28` (inline style, reactive)
- Preloader reads `useTheme()` for correct bg/text colors during loading

## Component convention
- Components should use `useTheme()` and inline styles keyed on `isDark`
- Tailwind dark: variants work via `darkMode: 'class'` in tailwind.config.js
- Global dark overrides live in `index.css` under `.dark` selectors

**Why:** CSS-class-based dark mode (vs `prefers-color-scheme`) allows user override and persists across sessions.

**How to apply:** Any new page/component should import `useTheme` and branch on `isDark` for colors that don't already pick up the CSS var system.
