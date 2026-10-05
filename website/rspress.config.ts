import path from 'node:path';

import { defineConfig } from '@rspress/core';

export default defineConfig({
  root: path.join(__dirname, 'docs'),
  title: 'RunBuoy',
  description: '扫一眼，掌握任务的进展。安装交给 Agent，状态带到 iPhone。',
  icon: '/brand/runbuoy-icon-light.png',
  logo: {
    light: '/brand/runbuoy-icon-light.png',
    dark: '/brand/runbuoy-icon-dark.png',
  },
  logoText: 'RunBuoy',
  lang: 'zh',
  locales: [
    {
      lang: 'zh',
      label: '简体中文',
      title: 'RunBuoy',
      description: '扫一眼，掌握任务的进展。安装交给 Agent，状态带到 iPhone。',
    },
    {
      lang: 'en',
      label: 'English',
      title: 'RunBuoy',
      description: 'Keep long-running tasks in sight on iPhone.',
    },
  ],
  base: '/',
  siteOrigin: 'https://www.runbuoy.cloud',
  globalStyles: path.join(__dirname, 'styles/index.css'),
  head: [
    [
      'link',
      {
        rel: 'icon',
        href: '/brand/runbuoy-icon-light.png',
        media: '(prefers-color-scheme: light)',
      },
    ],
    [
      'link',
      {
        rel: 'icon',
        href: '/brand/runbuoy-icon-dark.png',
        media: '(prefers-color-scheme: dark)',
      },
    ],
    [
      'link',
      {
        rel: 'apple-touch-icon',
        href: '/brand/apple-touch-icon.png',
      },
    ],
    route => [
      'meta',
      {
        property: 'og:image',
        content: `https://www.runbuoy.cloud/${route.lang === 'zh' ? 'marketing/zh-Hans/og.png' : 'og.png'}`,
      },
    ],
    [
      'meta',
      {
        property: 'og:image:width',
        content: '1200',
      },
    ],
    [
      'meta',
      {
        property: 'og:image:height',
        content: '630',
      },
    ],
    [
      'meta',
      {
        name: 'twitter:card',
        content: 'summary_large_image',
      },
    ],
  ],
  languageParity: {
    enabled: true,
  },
  themeConfig: {
    localeRedirect: 'never',
    lastUpdated: true,
    socialLinks: [
      {
        icon: 'github',
        mode: 'link',
        content: 'https://github.com/TANG617/RunBuoy',
      },
    ],
  },
});
