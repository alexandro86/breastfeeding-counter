import { ApiStatus } from './components/ApiStatus'
import { DashboardPage } from './features/dashboard/DashboardPage'
import { PlaceholderPage } from './routes/PlaceholderPage'

const navigation = [
  { label: 'Inicio', to: '/' },
  {
    label: 'Historial',
    to: '/historial',
    page: {
      eyebrow: 'Historial',
      title: 'Tus registros, en orden',
      description: 'Aquí aparecerán las tomas registradas y sus filtros.',
    },
  },
  {
    label: 'Productos',
    to: '/productos',
    page: {
      eyebrow: 'Productos',
      title: 'Todo lo que usas, a mano',
      description: 'El catálogo y los usos de productos llegarán en el Hito 3.',
    },
  },
  {
    label: 'Perfil',
    to: '/perfil',
    page: {
      eyebrow: 'Perfil',
      title: 'Tu espacio privado',
      description:
        'La cuenta, zona horaria y perfiles se implementarán en el Hito 1.',
    },
  },
]

export default function App() {
  const pathname = window.location.pathname.replace(/\/+$/, '') || '/'
  const currentItem = navigation.find((item) => item.to === pathname)

  return (
    <div className="app-shell">
      <header className="topbar">
        <a
          className="brand"
          href="/"
          aria-label="Breastfeeding Counter, inicio"
        >
          <span className="brand-mark" aria-hidden="true">
            bc
          </span>
          <span>
            <strong>Breastfeeding</strong>
            <small>counter</small>
          </span>
        </a>
        <ApiStatus />
      </header>

      <main id="main-content">
        {currentItem?.page ? (
          <PlaceholderPage {...currentItem.page} />
        ) : (
          <DashboardPage />
        )}
      </main>

      <nav className="bottom-nav" aria-label="Navegación principal">
        {navigation.map((item) => (
          <a
            key={item.to}
            href={item.to}
            className={pathname === item.to ? 'active' : undefined}
            aria-current={pathname === item.to ? 'page' : undefined}
          >
            <span aria-hidden="true" className="nav-dot" />
            {item.label}
          </a>
        ))}
      </nav>
    </div>
  )
}
