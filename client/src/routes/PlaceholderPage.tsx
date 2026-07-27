type PlaceholderPageProps = {
  eyebrow: string
  title: string
  description: string
}

export function PlaceholderPage({
  eyebrow,
  title,
  description,
}: PlaceholderPageProps) {
  return (
    <section className="placeholder-card">
      <p className="eyebrow">{eyebrow}</p>
      <h1>{title}</h1>
      <p className="placeholder-copy">{description}</p>
    </section>
  )
}
