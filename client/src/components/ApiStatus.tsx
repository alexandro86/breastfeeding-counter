import { useQuery } from '@tanstack/react-query'
import { getLiveness } from '../lib/api'

export function ApiStatus() {
  const statusQuery = useQuery({
    queryKey: ['api', 'liveness'],
    queryFn: ({ signal }) => getLiveness(signal),
    refetchInterval: 60_000,
  })

  const state = statusQuery.isPending
    ? 'loading'
    : statusQuery.isError
      ? 'error'
      : 'ready'

  const label =
    state === 'loading'
      ? 'Conectando'
      : state === 'error'
        ? 'API sin conexión'
        : 'API disponible'

  return (
    <span className="api-status" data-state={state} role="status">
      <span className="api-status-dot" aria-hidden="true" />
      {label}
    </span>
  )
}
