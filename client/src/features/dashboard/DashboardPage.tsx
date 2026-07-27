export function DashboardPage() {
  return (
    <section className="dashboard">
      <div className="hero-card">
        <p className="eyebrow">Tu día, más liviano</p>
        <h1>Un registro simple para cada momento.</h1>
        <p className="hero-copy">
          La fundación está lista para construir un seguimiento privado, claro y
          pensado para usar con una sola mano.
        </p>
        <button
          className="primary-action"
          type="button"
          disabled
          title="Disponible en el Hito 2"
        >
          Iniciar toma
        </button>
      </div>

      <div className="foundation-grid" aria-label="Estado de la fundación">
        <article className="info-card">
          <p className="card-kicker">Privacidad</p>
          <h2>Tus datos son tuyos</h2>
          <p>La API será la única responsable de autorizar cada registro.</p>
        </article>
        <article className="info-card">
          <p className="card-kicker">Confiabilidad</p>
          <h2>Tiempo real, incluso al volver</h2>
          <p>
            Los cronómetros se basarán en fechas persistidas, no en memoria
            local.
          </p>
        </article>
        <article className="info-card">
          <p className="card-kicker">Accesibilidad</p>
          <h2>Hecho para el teléfono</h2>
          <p>Controles cómodos, contraste claro y navegación predecible.</p>
        </article>
      </div>
    </section>
  )
}
