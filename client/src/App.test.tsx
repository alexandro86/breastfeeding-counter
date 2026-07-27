import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { render, screen } from '@testing-library/react'
import { http, HttpResponse } from 'msw'
import { describe, expect, it } from 'vitest'
import App from './App'
import { server } from './test/server'

function renderApp(initialPath = '/') {
  window.history.replaceState({}, '', initialPath)
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  })

  return render(
    <QueryClientProvider client={queryClient}>
      <App />
    </QueryClientProvider>,
  )
}

describe('App', () => {
  it('muestra la fundación y confirma la disponibilidad de la API', async () => {
    renderApp()

    expect(
      screen.getByRole('heading', {
        name: 'Un registro simple para cada momento.',
      }),
    ).toBeInTheDocument()
    expect(await screen.findByText('API disponible')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Iniciar toma' })).toBeDisabled()
  })

  it('informa cuando la API no responde correctamente', async () => {
    server.use(
      http.get('*/api/v1/health/live', () =>
        HttpResponse.json({ title: 'Unavailable' }, { status: 503 }),
      ),
    )

    renderApp()

    expect(await screen.findByText('API sin conexión')).toBeInTheDocument()
  })

  it('muestra las rutas preparadas para los siguientes hitos', async () => {
    renderApp('/perfil')

    expect(
      screen.getByRole('heading', { name: 'Tu espacio privado' }),
    ).toBeInTheDocument()
    expect(await screen.findByText('API disponible')).toBeInTheDocument()
  })
})
