import type { D1Database, D1PreparedStatement } from '@cloudflare/workers-types';

export class DbClient {
  constructor(readonly db: D1Database) {}

  prepare(sql: string): D1PreparedStatement {
    return this.db.prepare(sql);
  }

  async run(statement: D1PreparedStatement): Promise<void> {
    await statement.run();
  }

  async first<T>(statement: D1PreparedStatement): Promise<T | null> {
    return (await statement.first<T>()) ?? null;
  }

  async all<T>(statement: D1PreparedStatement): Promise<T[]> {
    const result = await statement.all<T>();
    return (result.results ?? []) as T[];
  }

  /** Batch statements in order (D1 batch API). */
  async batch(statements: D1PreparedStatement[]): Promise<void> {
    if (statements.length === 0) return;
    await this.db.batch(statements);
  }
}
