import { Router } from 'express';
import { z } from 'zod';
import { createSupabaseClient } from '../middleware/auth';
import { dbFailure, pagination, parse, sendPage } from '../utils/api';

const router = Router();
router.get('/', async (req, res, next) => {
  try {
    const { page, limit, from, to } = pagination(req.query);
    const date = new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Jakarta', year: 'numeric', month: '2-digit', day: '2-digit' }).format(new Date());
    const { data, error, count } = await (req.supabase ?? createSupabaseClient()).from('offers')
      .select('id,cafe_id,product_name,photo_url,original_price,discounted_price,start_date,end_date,cafes!inner(id,name,area,address)', { count: 'exact' })
      .eq('is_active', true).lte('start_date', date).gte('end_date', date).eq('cafes.is_active', true).eq('cafes.verification_status', 'verified').order('end_date').range(from, to);
    if (error) throw dbFailure(error); sendPage(req, res, data ?? [], page, limit, (count ?? 0) > to + 1);
  } catch (e) { next(e); }
});
export default router;
