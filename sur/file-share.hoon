|%
+$  card  card:agent:gall
+$  app-state  [=received =sent =sending =storage]
+$  received  (map @t [body=octs content-type=@t src=@p date=@da])
+$  sent  (list [[filename=@t date=@da] receiver=@p size=@ud status=(unit @da) error=(unit error-type)])
+$  sending  (map @t [filename=@t body=octs content-type=@t])
+$  storage  [capacity=@ud used=@ud]
+$  file-info  [filename=@t timestamp=@da eny=@t size=@ud]
+$  transfer-complete  [filename=@t timestamp-sent=@da timestamp-received=@da eny=@t]
+$  error-info  [filename=@t date=@da eny=@t =error-type]
+$  error-type  ?(%poke %storage %get-request %ip)
--
