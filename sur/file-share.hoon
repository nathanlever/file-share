|%
+$  card  card:agent:gall
+$  app-state  [=received =sent =sending =storage]
+$  received  (map @t [body=octs content-type=@t src=@p date=@da])
+$  sent  (list [[filename=@t date=@da] receiver=@p size=@t status=(unit @da)])
+$  sending  (map @t [filename=@t body=octs content-type=@t])
+$  storage  [capacity=@ used=@]
+$  file-info  [filename=@t timestamp=@da eny=@t size=@]
+$  transfer-complete  [filename=@t timestamp-sent=@da timestamp-received=@da eny=@t]
+$  error-info  [filename=@t date=@da message=@t]
--
