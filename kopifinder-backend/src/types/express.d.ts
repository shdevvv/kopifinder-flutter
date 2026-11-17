import type { SupabaseClient, User } from '@supabase/supabase-js';

declare global {
  namespace Express {
    interface Request {
      requestId: string;
      user?: User;
      supabase?: SupabaseClient;
    }
  }
}

export {};
