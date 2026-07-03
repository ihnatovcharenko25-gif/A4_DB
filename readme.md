overall structure:
(erd as photo in repository)





Exanple select: orders of customer with id = 2500

  Buffers: shared hit=3961
  ->  Sort  (cost=6752.22..6752.33 rows=45 width=74) (actual time=13.148..13.151 rows=36.67 loops=3)
        Sort Key: o.deadline DESC
        Sort Method: quicksort  Memory: 36kB
        Buffers: shared hit=3961
        Worker 0:  Sort Method: quicksort  Memory: 25kB
        Worker 1:  Sort Method: quicksort  Memory: 25kB
        ->  Nested Loop Left Join  (cost=0.71..6750.98 rows=45 width=74) (actual time=0.044..13.075 rows=36.67 loops=3)
              Buffers: shared hit=3947
              ->  Nested Loop  (cost=0.28..6377.45 rows=45 width=57) (actual time=0.037..12.678 rows=36.67 loops=3)
                    Buffers: shared hit=3507
                    ->  Parallel Seq Scan on orders o  (cost=0.00..6368.58 rows=45 width=22) (actual time=0.026..12.571 rows=36.67 loops=3)
                          Filter: (customer_id = 2500)
                          Rows Removed by Filter: 183297
                          Buffers: shared hit=3504
                    ->  Materialize  (cost=0.28..8.31 rows=1 width=39) (actual time=0.001..0.001 rows=1.00 loops=110)
                          Storage: Memory  Maximum Storage: 17kB
                          Buffers: shared hit=3
                          ->  Index Scan using customers_pkey on customers c  (cost=0.28..8.30 rows=1 width=39) (actual time=0.020..0.021 rows=1.00 loops=1)
                                Index Cond: (id = 2500)
                                Index Searches: 1
                                Buffers: shared hit=3
              ->  Index Scan using deliveries_order_id_key on deliveries d  (cost=0.42..8.30 rows=1 width=24) (actual time=0.008..0.008 rows=1.00 loops=110)
                    Index Cond: (order_id = o.id)
                    Index Searches: 110
                    Buffers: shared hit=440
Planning:
  Buffers: shared hit=30
Planning Time: 0.974 ms
Execution Time: 77.192 ms


with idx_orders_customer_id ON orders(customer_id);

Sort  (cost=1299.61..1299.88 rows=109 width=74) (actual time=0.576..0.581 rows=110.00 loops=1)
  Sort Key: o.deadline DESC
  Sort Method: quicksort  Memory: 36kB
  Buffers: shared hit=553 read=3
  ->  Nested Loop Left Join  (cost=5.98..1295.92 rows=109 width=74) (actual time=0.091..0.547 rows=110.00 loops=1)
        Buffers: shared hit=553 read=3
        ->  Nested Loop  (cost=5.55..391.14 rows=109 width=57) (actual time=0.082..0.202 rows=110.00 loops=1)
              Buffers: shared hit=113 read=3
              ->  Index Scan using customers_pkey on customers c  (cost=0.28..8.30 rows=1 width=39) (actual time=0.008..0.009 rows=1.00 loops=1)
                    Index Cond: (id = 2500)
                    Index Searches: 1
                    Buffers: shared hit=3
              ->  Bitmap Heap Scan on orders o  (cost=5.27..381.75 rows=109 width=22) (actual time=0.067..0.171 rows=110.00 loops=1)
                    Recheck Cond: (customer_id = 2500)
                    Heap Blocks: exact=110
                    Buffers: shared hit=110 read=3
                    ->  Bitmap Index Scan on idx_orders_customer_id  (cost=0.00..5.24 rows=109 width=0) (actual time=0.044..0.044 rows=110.00 loops=1)
                          Index Cond: (customer_id = 2500)
                          Index Searches: 1
                          Buffers: shared read=3
        ->  Index Scan using deliveries_order_id_key on deliveries d  (cost=0.42..8.30 rows=1 width=24) (actual time=0.003..0.003 rows=1.00 loops=110)
              Index Cond: (order_id = o.id)
              Index Searches: 110
              Buffers: shared hit=440
Planning:
  Buffers: shared hit=40 read=1
Planning Time: 1.798 ms
Execution Time: 0.614 ms


More than 100x faster, because index on customer in orders lets us efficiently find orders of particular customer

Parallel Seq Scan on orders o  (cost=0.00..6368.58 rows=45 width=22) (actual time=0.026..12.571 rows=36.67 loops=3)
                          Filter: (customer_id = 2500)
                          Rows Removed by Filter: 183297
                          Buffers: shared hit=3504
TO
 Bitmap Heap Scan on orders o  (cost=5.27..381.75 rows=109 width=22) (actual time=0.067..0.171 rows=110.00 loops=1)
                    Recheck Cond: (customer_id = 2500)
                    Heap Blocks: exact=110
                    Buffers: shared hit=110 read=3
      
