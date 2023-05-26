/-  *file-share
/+  default-agent, dbug
=>
|%
++  get-date
  |=  date=@da
^-  @t
  =/  year  (cat 3 '~' (crip (a-co:co y:(yore date))))
  =/  month  `@t`(cat 3 '.' (scot %ud m:(yore date)))
  =/  day  `@t`(cat 3 '.' (scot %ud d:t:(yore date)))
  =/  hour  `@t`(cat 3 ' ' (scot %ud h:t:(yore date)))
  =/  minute  ?:  (lth (lent (trip (scot %ud m:t:(yore date)))) 2)
    `@t`(cat 3 ':' (cat 3 '0' (scot %ud m:t:(yore date))))
  `@t`(cat 3 ':' (scot %ud m:t:(yore date)))
  `@t`(cat 3 year (cat 3 month (cat 3 day (cat 3 hour minute))))
::
++  get-size
  |=  s=@ud
  ^-  @t
  ?:  (gth s 999.999)
    =/  size  (dvr s 1.000.000)
    =/  decimal  (div q.size 100.000)
    `@t`(cat 3 (scot %ud p.size) (cat 3 ',' (cat 3 (scot %ud decimal) ' MB')))
  ?:  (gth s 999)
    =/  size  (dvr s 1.000)
    =/  decimal  (div q.size 100)
    `@t`(cat 3 (scot %ud p.size) (cat 3 ',' (cat 3 (scot %ud decimal) ' KB')))
  `@t`(cat 3 (scot %ud s) ' B')
::
++  get-sent-index
  |=  [filename=@t date=@da =sent]
  ^-  @ud
  =/  compare  [filename date]
  =/  i  0
  |-
    ^-  @ud
    =/  sent-file  (snag i sent)
    ?:  =(compare -.sent-file)
      i
    $(i +(i))
::
++  check-filename-duplicate
  |=  [filename=@t state=app-state]
  ^-  @t
    =/  i  0
    =/  filename-length  (lent (trip filename))
    =/  filename-name  |-
      ^-  @t
      ?:  =((snag i (trip filename)) '.')
        (cut 3 [0 i] filename)
      $(i +(i))
    =.  i  (lent (trip filename-name))
    =/  filename-extension  (cut 3 [i filename-length] filename)
    =.  i  0
    |-
      ^-  @t
      ?.  (~(has by received.state) filename)
        filename
      =.  i  (add i 1)
      =/  filename-number  (cat 3 '_' (scot %ud i))
      $(filename (cat 3 filename-name (cat 3 filename-number filename-extension)))
::
++  http-login-redirect
  |=  [req=(pair @ta inbound-request:eyre) state=app-state]
  ^-  (quip card app-state)
    =/  =response-header:http
      :-  301
      :~  ['Location' '/~/login?redirect=/file-share']
      ==
    :_  state
    :~
      [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
      [%give %fact [/http-response/[p.req]]~ %http-response-data !>(~)]
      [%give %kick [/http-response/[p.req]]~ ~]
    ==
::
++  invalid-http-request-method
  |=  [req=(pair @ta inbound-request:eyre) state=app-state]
  ^-  (quip card app-state)
    =/  data=octs
      (as-octs:mimes:html '<h1>405 Method Not Allowed</h1>')
    =/  content-length=@t
      (crip ((d-co:co 1) p.data))
    =/  =response-header:http
      :-  405
      :~  ['Content-Length' content-length]
          ['Content-Type' 'text/html']
          ['Allow' 'GET']
      ==
    :_  state
    :~
      [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
      [%give %fact [/http-response/[p.req]]~ %http-response-data !>(`data)]
      [%give %kick [/http-response/[p.req]]~ ~]
    ==
::
++  invalid-ship-redirect
  |=  [req=(pair @ta inbound-request:eyre) state=app-state ship=(unit @p)]
  ^-  (quip card app-state)
  =/  =response-header:http
    :-  301
    :~  ['Location' '/file-share/invalid-input']
    ==
  :_  state
  :~
    [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
    [%give %fact [/http-response/[p.req]]~ %http-response-data !>(~)]
    [%give %kick [/http-response/[p.req]]~ ~]
  ==
::
++  file-share-post
  |=  [req=(pair @ta inbound-request:eyre) state=app-state our=@p now=@da eny=@t]
  ^-  (quip card app-state)
  =/  data=octs  +.body.request.q.req
  =/  ship-start  0xa0d.0a0d
  =/  ship-end  0xa0d
  =/  filename-start  0x223d.656d.616e.656c.6966
  =/  filename-end  0x22
  =/  content-type-start  0x203a.6570.7954.2d74.6e65.746e.6f43
  =/  content-type-end  0xa0d
  =/  start  0xa0d.0a0d
  =/  end  0x2d2d.0a0d
  =/  i  0
  =/  ship  |-
    ^-  (unit @p)
    =/  compare  `@ux`(cut 3 [i 4] q.data)
    ?:  =(ship-start compare)
      =.  i  (add i 4)
      =/  j  i
      =/  end  |-
        ^-  @ud
        =.  compare  `@ux`(cut 3 [j 2] q.data)
        ?:  =(ship-end compare)
          j
        $(j +(j))
      =/  ship-result  (slaw %p `@t`(cut 3 [i (sub end i)] q.data))
      ?~  ship-result
        ~
      [~ `@p`u.ship-result]
    $(i +(i))
  ?~  ship
    (invalid-ship-redirect req state ship)
  ?.  ?|  ?=(%duke (clan:title u.ship))
          ?=(%king (clan:title u.ship))
          ?=(%czar (clan:title u.ship))
      ==
    (invalid-ship-redirect req state ship)
  =/  filename  |-
    ^-  @t
    =/  compare  `@ux`(cut 3 [i 10] q.data)
    ?:  =(filename-start compare)
      =.  i  (add i 10)
      =/  j  i
      =/  end  |-
        ^-  @ud
        =.  compare  `@ux`(cut 3 [j 1] q.data)
        ?:  =(filename-end compare)
          j
        $(j +(j))
      `@t`(cut 3 [i (sub end i)] q.data)
    $(i +(i))
  =/  content-type  |-
    ^-  @t
    =/  compare  `@ux`(cut 3 [i 14] q.data)
    ?:  =(content-type-start compare)
      =.  i  (add i 14)
      =/  j  i
      =/  end  |-
        ^-  @ud
        =.  compare  `@ux`(cut 3 [j 2] q.data)
        ?:  =(content-type-end compare)
          j
        $(j +(j))
      `@t`(cut 3 [i (sub end i)] q.data)
    $(i +(i))
  =/  k  0
  =.  data  |-
    ^-  octs
    =/  compare  `@ux`(cut 3 [i 4] q.data)
    ?:  &(=(start compare) =(k 1))
      =.  i  (add i 4)
      =/  head  (sub p.data i)
      =/  tail  `@ux`(cut 3 [i (sub -.data i)] q.data)
      [head `@`tail]
    ?:  =(start compare)
      $(i +(i), k +(k))
    $(i +(i))
  =.  i  4
  =/  result  |-
    ^-  [@t octs @t]
    =/  compare  `@ux`(cut 3 [(sub p.data i) 4] q.data)
    ?:  =(end compare)
      =.  p.data  (sub p.data i)
      =.  q.data  `@ux`(cut 3 [0 p.data] q.data)
      [filename data content-type]
    $(i +(i))
  =.  used.storage.state  (add used.storage.state p.-.+.result)
  ?:  =(u.ship our)
    =.  filename  (check-filename-duplicate filename state)
    =/  received  received.state
    =.  received  (~(put by received.state) filename [-.+.result content-type our now])
    =/  =response-header:http
      :-  301
      :~  ['Location' '/file-share']
      ==
    :_  [received sent.state sending.state storage.state]
    :~
      [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
      [%give %fact [/http-response/[p.req]]~ %http-response-data !>(~)]
      [%give %kick [/http-response/[p.req]]~ ~]
    ==
  =.  sent.state  ?:  =((lent sent.state) 10)
    [[[filename now] u.ship p.-.+.result ~] (oust [9 1] sent.state)]
  [[[filename now] u.ship p.-.+.result ~] sent.state]
  =/  =response-header:http
    :-  301
    :~  ['Location' '/file-share']
    ==
  :_  [received.state sent.state (~(put by sending.state) eny result) storage.state]
  :~
    [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
    [%give %fact [/http-response/[p.req]]~ %http-response-data !>(~)]
    [%give %kick [/http-response/[p.req]]~ ~]
    ?:  =(body.request.q.req ~)
      !!
    [%pass /send-url/[filename]/[(scot %da now)]/[eny] %agent [u.ship %file-share] %poke %file-share-initiate !>([filename now eny p.-.+.result])]
  ==
::
++  set-capacity
  |=  [req=(pair @ta inbound-request:eyre) state=app-state]
  ^-  (quip card app-state)
  ?<  ?=(~ body.request.q.req)
  =/  new-capacity  `@ud`(slav %ud (crip (oust [0 9] (trip q.u.body.request.q.req))))
  =.  storage.state  ?:  (gte (mul new-capacity 1.000.000) used.storage.state)
    [(mul new-capacity 1.000.000) used.storage.state]
  storage.state
  =/  =response-header:http
    :-  301
    :~  ['Location' '/file-share']
    ==
  :_  [received.state sent.state sending.state storage.state]
  :~
    [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
    [%give %fact [/http-response/[p.req]]~ %http-response-data !>(~)]
    [%give %kick [/http-response/[p.req]]~ ~]
  ==
::
++  delete-file
  |=  [req=(pair @ta inbound-request:eyre) state=app-state filename=@t]
  ^-  (quip card app-state)
  =/  file  (~(got by received.state) filename)
  =.  used.storage.state  (sub used.storage.state p.body.file)
  =/  =response-header:http
    :-  301
    :~  ['Location' '/file-share']
    ==
  :_  [(~(del by received.state) filename) sent.state sending.state storage.state]
  :~
    [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
    [%give %fact [/http-response/[p.req]]~ %http-response-data !>(~)]
    [%give %kick [/http-response/[p.req]]~ ~]
  ==
::
++  delete-sent
  |=  [req=(pair @ta inbound-request:eyre) state=app-state filename=@t date=@da]
  ^-  (quip card app-state)
  =/  i  (get-sent-index filename date sent.state)
  =/  sent-file  (snag i sent.state)
  =.  used.storage.state  ?~  status.sent-file
    (sub used.storage.state size.sent-file)
  used.storage.state
  ?:  =((lent sent.state) 1)
    =/  =response-header:http
      :-  301
      :~  ['Location' '/file-share']
      ==
    :_  [received.state (oust [i 1] sent.state) sending.state storage.state]
    :~
      [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
      [%give %fact [/http-response/[p.req]]~ %http-response-data !>(~)]
      [%give %kick [/http-response/[p.req]]~ ~]
    ==
  =/  =response-header:http
    :-  301
    :~  ['Location' '/file-share/more-sent']
    ==
  :_  [received.state (oust [i 1] sent.state) sending.state storage.state]
  :~
    [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
    [%give %fact [/http-response/[p.req]]~ %http-response-data !>(~)]
    [%give %kick [/http-response/[p.req]]~ ~]
  ==
::
++  style
  ^~
  %-  trip
  '''
  body {
    height: 99%;
    font-family: Inter,-apple-system,BlinkMacSystemFont,Roboto,Helvetica,Arial,sans-serif,"Apple Color Emoji";
    font-size: 14px;
    display: flex;
    flex-direction: column;
    align-items: center;
  }
  #app {
    display: flex;
    flex-direction: column;
    align-items: center;
    border: 1px solid #d0d0d0;
    color: grey;
    margin: 48px 0px;
  }
  #capacity-manager {
    display: flex;
    flex-direction: column;
    align-items: center;
    border: 1px solid #d0d0d0;
    color: grey;
  }
  .header-wrapper {
    width: 256px;
    border-bottom: 1px solid #d0d0d0;
    display: flex;
    flex-direction: row;
    align-items: center;
    justify-content: center;
    padding: 32px;
  }
  .header-wrapper2 {
    border-bottom: 1px solid #d0d0d0;
    padding: 32px;
  }
  .header {
    font-weight: 200;
    font-size: 26px;
    margin: 0;
  }
  .header2 {
    padding: 16px 0px 0px 0px;
  }
  .menu-wrapper {
    display: flex;
    justify-content: center;
    flex-direction: column;
    padding: 32px;
  }
  .menu-wrapper2 {
    width: 299px;
  }
  form {
    display: flex;
    justify-content: center;
    flex-direction: column;
    margin: 0px;
  }
  .list-item {
    display: flex;
    justify-content: start;
    flex-direction: row;
    margin: 16px 0px;
  }
  table {
    width: 100%;
  }
  .table-div {
    padding-bottom: 16px;
  }
  .table-div-received {
    padding-bottom: 32px;
  }
  table, th, td {
    border: 1px solid #d0d0d0;
    border-collapse: collapse;
    color: #404040;
    font-size: 15px;
    font-weight: 300;
  }
  tr {
    text-align: left;
  }
  th, td {
    padding: 14px 32px 14px 16px;
  }
  th {
    font-size: 16px;
    font-weight: 600;
    color: black;
  }
  p {
    margin: 0px;
  }
  #available-green {
    background-color: #c1ffc3;
  }
  #available-yellow {
    background-color: #fff7b2;
  }
  #available-red {
    background-color: #ffdddb;
  }
  .delete-button-wrapper {
    padding: 0px;
  }
  .delete-button {
    border: none;
    padding: 15px 32px;
    color: #404040;
  }
  .delete-button:hover {
    background-color: #dadada;
    cursor: pointer;
  }
  .delete-button:active {
    background-color: #c8c8c8;
  }
  label {
    font-size: 15px;
    font-weight: 300;
    margin-left: 6px;
    margin-bottom: 10px;
  }
  input {
    padding: 12px;
  }
  #file-input {
    padding: 0px 0px 18px;
  }
  .input-row {
    display: flex;
    flex-direction: column;
    padding-bottom: 8px;
  }
  .input-row2 {
    padding-bottom: 4px;
  }
  .input-row3 {
    padding-bottom: 16px;
  }
  .input-error {
    font-size: 10px;
    color: red;
    padding-left: 4px;
    padding-bottom: 4px;
  }
  .input-error-hidden {
    visibility: hidden;
  }
  .input-error-visible {
    visibility: visible;
  }
  #submit-button {
    padding: 12px;
  }
  #capacity-field {
    display: flex;
    flex-direction: row;
    align-items: center;
    justify-content: space-between;
    font-size: 14px;
  }
  #storage-button {
    margin-left: 16px;
  }
  #status-field {
    background-color: #fff7b2;
    display: flex;
    flex-direction: row;
    align-items: center;
    justify-content: space-between;
    padding-right: 16px;
  }
  #status-field2 {
    background-color: #c1ffc3;
    padding-right: 16px;
  }
  #status-field3 {
    background-color: #ffdddb;
  }
  #status-field4 {
    background-color: #fff7b2;
    display: flex;
    flex-direction: row;
    align-items: center;
    justify-content: space-between;
    padding-right: 16px;
  }
  #reload-button {
    margin-left: 16px;
  }
  #more-sent {
    display: flex;
    flex-direction: column;
    align-items: end;
    padding: 8px 12px 8px;
    font-weight: 300;
  }
  #more-sent-empty {
    margin-bottom: 16px;
    color: white;
  }
  .back-button {
    display: flex;
    flex-direction: column;
    align-items: start;
    padding: 0px 14px 16px;
  }
  .back-button2 {
    margin-top: 56px;
    padding-bottom: 18px;
    padding-left: 16px;
  }
  #empty-row {
    border-right-color: white;
  }
  @media only screen and (max-width: 800px) {
    th, td {
      padding: 7px 16px 7px 8px;
    }
  }
  @media only screen and (max-width: 600px) {
    th, td {
      padding: 0px;
    }
  }
  '''
::
++  file-share-get
  |=  [req=(pair @ta inbound-request:eyre) state=app-state our=@p valid-ship=?]
  ^-  (quip card app-state)
  =/  body
    %-  as-octs:mimes:html
    %-  crip
    %-  en-xml:html
      ;html
        ;head
          ;title:"File-Share"
          ;meta(charset "utf-8");
          ;meta(name "viewport", content "width=device-width, initial-scale=1");
          ;style: {style}
        ==
        ;body
          ;div#app
            ;div.header-wrapper
              ;h5.header: File-Share
            ==
            ;div.menu-wrapper
              ;form(method "post", action "/file-share", enctype "multipart/form-data")
                ;div.input-row.input-row2
                  ;label(for "ship"):"Ship"
                  ;input(type "text", name "ship", maxlength "14");
                ==
                ;+  ?:  ?=(%.y valid-ship)
                      ;p.input-error.input-error-hidden: *
                    ;p.input-error.input-error-invisible: *Invalid input
                ;div.input-row
                  ;input#file-input(type "file", name "file");
                  ;button#submit-button:"Submit"
                ==
              ==
            ==
          ==
          ;div#tables
            ;+  ?<  ?=(~ storage.state)
                  =/  used-percentage  (oust [0 2] (scow %s (need (toi:rd (mul:rd (div:rd (sun:rd used.storage.state) (sun:rd capacity.storage.state)) (sun:rd 100))))))
                  =/  available-storage  (get-size (sub capacity.storage.state used.storage.state))
                  =/  dvr1  ?:  =(used.storage.state 0)
                    [p=0 q=0]
                  (dvr capacity.storage.state used.storage.state)
                  ;div.table-div
                    ;table
                      ;tr
                        ;td#capacity-field
                          Storage Capacity: {(trip (get-size capacity.storage.state))}
                          ;a#storage-button/"/file-share/capacity": Manage
                        ==
                        ;td: Used: {(trip (get-size used.storage.state))} / {used-percentage} %
                        ;+  ?:  =(p.dvr1 1)
                              =/  dvr2  (dvr capacity.storage.state q.dvr1)
                              ?:  (gte p.dvr2 4)
                                ?:  (gte p.dvr2 10)
                                  ;td#available-red: Available: {(trip available-storage)}
                                ;td#available-yellow: Available: {(trip available-storage)}
                              ;td#available-green: Available: {(trip available-storage)}
                            ;td#available-green: Available: {(trip available-storage)}
                      ==
                    ==
                  ==
            ;+  ?:  =(sent.state ~)
                  ;div.table-div
                    ;table
                      ;tr
                        ;th: LAST SENT
                        ;th: To
                        ;th: Date
                        ;th: Size
                        ;th: Status
                      ==
                      ;tr
                        ;td#empty-row
                          ;p: No files sent.
                        ==
                      ==
                    ==
                  ==
                =/  last  (snag 0 sent.state)
                ;div.table-div
                  ;table
                    ;tr
                      ;th: LAST SENT
                      ;th: To
                      ;th: Date
                      ;th: Size
                      ;th: Status
                    ==
                    ;div
                      ;tr
                        ;td
                          ;p: {(trip filename.last)}
                        ==
                        ;td
                          ;p: {(scow %p receiver.last)}
                        ==
                        ;td
                          ;p: {(trip (get-date date.last))}
                        ==
                        ;td
                          ;p: {(trip (get-size size.last))}
                        ==
                        ;+  ?~  status.last
                          ;td#status-field
                            ;p: Pending
                            ;a#reload-button/"/file-share": R
                          ==
                        ?:  =(`@da`0 u.status.last)
                          ;td#status-field3
                            ;p: ERR=IP
                          ==
                        ?:  =(`@da`1 u.status.last)
                          ;td#status-field3
                            ;p: ERR=STORAGE
                          ==
                        ?:  =(`@da`2 u.status.last)
                          ;td#status-field3
                            ;p: ERR=GET_REQUEST
                          ==
                        ?:  =(`@da`3 u.status.last)
                          ;td#status-field3
                            ;p: ERR=POKE-FAILED
                          ==
                        ;td#status-field2
                          ;p: {(trip (get-date u.status.last))}
                        ==
                      ==
                    ==
                  ==
                  ;+  ?:  (gth (lent sent.state) 1)
                        ;div#more-sent
                          ;a/"/file-share/more-sent": Show more...
                        ==
                      ;div#more-sent-empty
                        ;p: -
                      ==
                ==
            ;+  ?:  =(received.state ~)
                  ;div.table-div
                    ;table
                      ;tr
                        ;th: RECEIVED FILES
                        ;th: To
                        ;th: Date
                        ;th: Size
                      ==
                      ;tr
                        ;td#empty-row
                          ;p: No files received.
                        ==
                      ==
                    ==
                  ==
                =/  files-list  ~(tap by received.state)
                ;div.table-div.table-div-received
                  ;table
                    ;tr
                      ;th: RECEIVED FILES
                      ;th: From
                      ;th: Date
                      ;th: Size
                    ==
                    ;div
                      ;*  %+  turn  files-list
                      |=  [filename=@t [body=octs content-type=@t src=@p date=@da]]
                        ;tr
                          ;td
                            ;a/"/file-share?grid-note=%2F{(en-urlt:html (trip filename))}": {(trip filename)}
                          ==
                          ;td
                            ;p: {(scow %p src)}
                          ==
                          ;td
                            ;p: {(trip (get-date date))}
                          ==
                          ;td
                            ;p: {(trip (get-size p.body))}
                          ==
                          ;td.delete-button-wrapper
                            ;form(method "post", action "/file-share/{(en-urlt:html (trip filename))}/delete", enctype "multipart/form-data")
                              ;button.delete-button: Delete
                            ==
                          ==
                        ==
                    ==
                  ==
                ==
            ==
        ==
      ==
  =/  =response-header:http
    :-  200
    :~  ['content-type' 'text/html; charset=utf-8']
    ==
  :_  state
  :~
    [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
    [%give %fact [/http-response/[p.req]]~ %http-response-data !>(`body)]
    [%give %kick [/http-response/[p.req]]~ ~]
  ==
::
++  get-storage-page
  |=  [req=(pair @ta inbound-request:eyre) state=app-state]
  ^-  (quip card app-state)
  =/  used  (add (div used.storage.state 1.000.000) 1)
  =/  body
    %-  as-octs:mimes:html
    %-  crip
    %-  en-xml:html
      ;html
        ;head
          ;title:"File-Share"
          ;meta(charset "utf-8");
          ;meta(name "viewport", content "width=device-width, initial-scale=1");
          ;style: {style}
        ==
        ;body
          ;div#tables
            ;div.back-button.back-button2
              ;a/"/file-share": << BACK
            ==
            ;div#capacity-manager
              ;div.header-wrapper2
                ;h5.header: File-Share Storage Manager
              ==
              ;div.menu-wrapper.menu-wrapper2
                ;form(method "post", action "/file-share/capacity", enctype "application/x-www-form-urlencoded")
                ;div.input-row.input-row3
                    ;label(for "capacity"):"Set Storage Capacity ({(scow %ud used)}-100 MB):"
                    ;input(type "number", name "capacity", min "{(scow %ud used)}", max "100");
                  ==
                  ;div.input-row
                    ;button#submit-button:"Submit"
                  ==
                ==
              ==
            ==
          ==
        ==
      ==
  =/  =response-header:http
    :-  200
    :~  ['content-type' 'text/html; charset=utf-8']
    ==
  :_  state
  :~
    [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
    [%give %fact [/http-response/[p.req]]~ %http-response-data !>(`body)]
    [%give %kick [/http-response/[p.req]]~ ~]
  ==
::
++  get-more-sent
  |=  [req=(pair @ta inbound-request:eyre) state=app-state]
  ^-  (quip card app-state)
  =/  body
    %-  as-octs:mimes:html
    %-  crip
    %-  en-xml:html
      ;html
        ;head
          ;title:"File-Share"
          ;meta(charset "utf-8");
          ;meta(name "viewport", content "width=device-width, initial-scale=1");
          ;style: {style}
        ==
        ;body
          ;div
            ;h5.header.header2: File-Share: Latest Sent Files
          ==
          ;div#tables
            ;div.back-button
              ;a/"/file-share": << BACK
            ==
            ;+  ?:  =(sent.state ~)
                  ;div#sent-table
                    ;table
                      ;tr
                        ;th: LAST SENT
                        ;th: To
                        ;th: Date
                        ;th: Size
                        ;th: Status
                      ==
                      ;tr
                        ;td#empty-row
                          ;p: No files sent.
                        ==
                      ==
                    ==
                  ==
                ;div#latest-sent
                  ;table
                    ;tr
                      ;th: Filename
                      ;th: To
                      ;th: Date
                      ;th: Size
                      ;th: Status
                    ==
                    ;div
                      ;*  %+  turn  sent.state
                      |=  [[filename=@t date=@da] receiver=@p size=@ud status=(unit @da)]
                        ;tr
                          ;td
                            ;p: {(trip filename)}
                          ==
                          ;td
                            ;p: {(scow %p receiver)}
                          ==
                          ;td
                            ;p: {(trip (get-date date))}
                          ==
                          ;td
                            ;p: {(trip (get-size size))}
                          ==
                          ;+  ?~  status
                            ;td#status-field4
                              ;p: Pending
                              ;a#reload-button/"/file-share": R
                            ==
                          ?:  =(`@da`0 u.status)
                            ;td#status-field3
                              ;p: ERR=IP
                            ==
                          ?:  =(`@da`1 u.status)
                            ;td#status-field3
                              ;p: ERR=STORAGE
                            ==
                          ?:  =(`@da`2 u.status)
                            ;td#status-field3
                              ;p: ERR=GET_REQUEST
                            ==
                          ?:  =(`@da`3 u.status)
                          ;td#status-field3
                            ;p: ERR=POKE-FAILED
                          ==
                          ;td#status-field2
                            ;p: {(trip (get-date u.status))}
                          ==
                          ;td.delete-button-wrapper
                          ;form(method "post", action "/file-share/{(en-urlt:html (trip filename))}/{(en-urlt:html (trip (scot %da date)))}/delete", enctype "multipart/form-data")
                              ;button.delete-button: Remove
                            ==
                          ==
                        ==
                    ==
                  ==
                ==
          ==
        ==
      ==
  =/  =response-header:http
    :-  200
    :~  ['content-type' 'text/html; charset=utf-8']
    ==
  :_  state
  :~
    [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
    [%give %fact [/http-response/[p.req]]~ %http-response-data !>(`body)]
    [%give %kick [/http-response/[p.req]]~ ~]
  ==
::
++  page-not-found-response
  |=  [req=(pair @ta inbound-request:eyre) state=app-state]
  ^-  (quip card app-state)
    =/  =response-header:http
    :-  404
    :~  ['Content-Type' 'text/html']
    ==
  :_  state
  :~
    [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
    [%give %fact [/http-response/[p.req]]~ %http-response-data !>(~)]
    [%give %kick [/http-response/[p.req]]~ ~]
  ==
::
++  get-file-response
  |=  [req=(pair @ta inbound-request:eyre) state=app-state eny=@t]
  ^-  (quip card app-state)
  =/  file=[filename=@t body=octs content-type=@t]  (~(got by sending.state) eny)
  =/  =response-header:http
    :-  200
    :~  ['content-type' content-type.file]
    ==
  :_  state
  :~
    [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
    [%give %fact [/http-response/[p.req]]~ %http-response-data !>([~ body.file])]
    [%give %kick [/http-response/[p.req]]~ ~]
  ==
::
++  download-file
  |=  [req=(pair @ta inbound-request:eyre) state=app-state filename=@t]
  ^-  (quip card app-state)
  =/  file  (~(get by received.state) filename)
  =/  =response-header:http
    :-  200
    :~  ['content-type' content-type.+.+.file]
        ['content-disposition' (crip "attachment; filename=\"{(trip filename)}\"")]
    ==
  :_  state
  :~
    [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
    [%give %fact [/http-response/[p.req]]~ %http-response-data !>(`-.+.file)]
    [%give %kick [/http-response/[p.req]]~ ~]
  ==
::
++  request-file
  |=  [=file-info our=@p now=@da src=@p]
  ^-  (list card)
  =/  src-state  .^(ship-state:ames %ax /[(scot %p our)]//[(scot %da now)]/peers/[(scot %p src)])
  ?>  ?=(%known -.src-state)
  ?<  ?=(~ route.src-state)
  =/  lane  lane.u.route.src-state
  ?:  -.lane
    [[%pass /failed %agent [src %file-share] %poke %file-share-failed !>([filename.file-info timestamp.file-info 'ip'])] ~]
  =/  ip  (scot %if `@if`p.lane)
  =/  ip-length  (lent (trip ip))
  =.  ip  (cut 3 [1 ip-length] ip)
  =/  download-url  `@t`(cat 3 (cat 3 (cat 3 'http://' ip) '/file-share/') eny.file-info)
  =/  =request:http  [%'GET' download-url ~ ~]
  [[%pass /get-file/[filename.file-info]/[(scot %da timestamp.file-info)]/[eny.file-info]/[(scot %p src)] %arvo %i %request request *outbound-config:iris] ~]
--
::
::  Main
::
^-  agent:gall
=|  state=app-state
%-  agent:dbug
|_  =bowl:gall
+*  this  .
    default  ~(. (default-agent this %|) bowl)
::
++  on-init
  ^-  (quip card _this)
  [[%pass /bind-url %arvo %e %connect `/'file-share' %file-share]~ this]
++  on-save
  ^-  vase
  !>  state
++  on-load
  |=  v=vase
  ^-  (quip card _this)
  =/  old  !<  app-state  v
  `this(state old)
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?+    mark
    (on-poke:default [mark vase])
  ::
      %handle-http-request
    =/  req  !<  (pair @ta inbound-request:eyre)  vase
    =/  result
    =/  url-length  (lent (trip url.request.q.req))
    ?:  ?&  (gth url-length 150)
            ?=(%'GET' method.request.q.req)
        ==
      =/  purl  (rash url.request.q.req apat:de-purl:html)
      =/  eny  (snag 1 q.purl)
      ?:  (~(has by sending.state) eny)
        (get-file-response req state eny)
      (http-login-redirect req state)
    ?.  authenticated.q.req
      (http-login-redirect req state)
    ?+    method.request.q.req
      (invalid-http-request-method req state)
    ::
        %'POST'
      ?:  =(url.request.q.req '/file-share')
        =/  eny  (crip (a-co:co eny.bowl))
        (file-share-post req state our.bowl now.bowl eny)
      ?:  =(url.request.q.req '/file-share/capacity')
        (set-capacity req state)
      =/  purl  (rash url.request.q.req apat:de-purl:html)
      =/  purl-length  (lent q.purl)
      ?:  =((snag (sub purl-length 1) q.purl) 'delete')
        =/  url-filename-encoded  (de-urlt:html (trip (snag 1 q.purl)))
        =/  url-filename  ?~  url-filename-encoded
          !!
        (crip u.url-filename-encoded)
        ?:  =((lent q.purl) 3)
          ?:  ?&  (~(has by received.state) url-filename)
                =(url.request.q.req (crip "/file-share/{(en-urlt:html (trip url-filename))}/delete"))
              ==
            (delete-file req state url-filename)
          `state
        ?:  =((lent q.purl) 4)
          =/  url-date-encoded  (de-urlt:html (trip (snag 2 q.purl)))
          =/  url-date  ?~  url-date-encoded
            !!
          `@da`(slav %da (crip u.url-date-encoded))
          ::  =/  compare  [url-filename url-date]
          ::  =/  i  0
          ::  =.  i  |-
          ::    ^-  @ud
          ::    =/  sent-file  (snag i sent.state)
          ::    ?:  =(compare -.sent-file)
          ::      i
          ::    $(i +(i))
          (delete-sent req state url-filename url-date)
        !!
      !!
    ::
        %'GET'
      ::  ~&  state
      ?:  =(url.request.q.req '/file-share')
        (file-share-get req state our.bowl %.y)
      ?:  =(url.request.q.req '/file-share/invalid-input')
        (file-share-get req state our.bowl %.n)
      ?:  =(url.request.q.req '/file-share/capacity')
        (get-storage-page req state)
      ?:  =(url.request.q.req '/file-share/more-sent')
        (get-more-sent req state)
      ?:  =(received.state ~)
        (page-not-found-response req state)
      =/  url-length  (lent (trip url.request.q.req))
      =/  url-filename-de-encoded  (de-urlt:html (trip (cut 3 [25 url-length] url.request.q.req)))
      =/  url-filename  ?~  url-filename-de-encoded
        !!
      (crip u.url-filename-de-encoded)
      ::  ?:  ?&  =(url.request.q.req (cat 3 '/file-share?grid-note=%2F' (crip (en-urlt:html (trip url-filename)))))
      ::  ?:  ?&  =(url.request.q.req (cat 3 '/file-share?grid-note=%2F' url-filename))
      ::          (~(has by received.state) url-filename)
      ::      ==
      ?:  (~(has by received.state) url-filename)
        (download-file req state url-filename)
      (page-not-found-response req state)
    ==
    =.  state  +.result
    [-.result this]
  ::
      %file-share-initiate
    =/  inbound-file  !<  file-info  vase
    ?:  (gth (sub capacity.storage.state used.storage.state) size.inbound-file)
      [(request-file inbound-file our.bowl now.bowl src.bowl) this]
    :_  this
    :~
      [%pass /failed %agent [src.bowl %file-share] %poke %file-share-failed !>([filename.inbound-file timestamp.inbound-file 'storage'])]
    ==
  ::
      %file-share-complete
    =/  file  !<  transfer-complete  vase
    =/  i  (get-sent-index filename.file timestamp-sent.file sent.state)
    =/  sent  sent.state
    =/  sent-file  (snag i sent)
    =.  status.sent-file  [~ timestamp-received.file]
    =.  sent  (oust [i 1] sent)
    =.  sent  (into sent i sent-file)
    =/  sending-file  (~(got by sending.state) eny.file)
    =/  storage  storage.state
    =.  used.storage  (sub used.storage -.-.+.sending-file)
    `this(state [received.state sent (~(del by sending.state) eny.file) storage])
  ::
      %file-share-failed
    =/  error  !<  error-info  vase
    =/  i  (get-sent-index filename.error date.error sent.state)
    =/  sent  sent.state
    =/  sent-file  (snag i sent)
    =.  status.sent-file  ?:  =(message.error 'ip')
      [~ `@da`0]
    ?:  =(message.error 'storage')
      [~ `@da`1]
    ?:  =(message.error 'get-request')
      [~ `@da`2]
    ?:  =(message.error 'poke')
      [~ `@da`3]
    !!
    =.  sent  (oust [i 1] sent)
    =.  sent  (into sent i sent-file)
    `this(sent.state sent)
  ==
::
++  on-watch
  |=  =path
  ^-  (quip card _this)
  ?+    path
    (on-watch:default path)
  ::
      [%http-response *]
    `this
  ==
++  on-leave  on-leave:default
++  on-peek   on-peek:default
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)
  ?+   wire  (on-agent:default wire sign)
      [%send-url @ @ @ ~]
    ?.  ?=(%poke-ack -.sign)
      (on-agent:default wire sign)
    ?~  p.sign
      %-  (slog '%pokeit: File-share successful!' ~)
      `this
    %-  (slog '%pokeit: File-share unsuccessful!' ~)
    =/  eny  `@t`i.t.t.t.wire
    =/  sending-file  (~(got by sending.state) eny)
    =.  used.storage.state  (sub used.storage.state p.body.sending-file)
    =.  sending.state  (~(del by sending.state) eny)
    :_  this
    :~
    [%pass /failed %agent [our.bowl %file-share] %poke %file-share-failed !>([`@t`i.t.wire `@da`(slav %da i.t.t.wire) 'poke'])]
    ==
  ==
++  on-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip card _this)
  ?+  wire  `this
      [%bind-url ~]
    ?>  ?=([%eyre %bound *] sign-arvo)
    ?:  =(accepted.sign-arvo %.y)
      ~&  "binding successful"
      `this(storage.state [100.000.000 0])
    ~&  "binding unsuccessful"
    `this
      [%get-file @ @ @ @ ~]
    ?>  ?=([%iris %http-response %finished *] sign-arvo)
      =/  src  `@t`i.t.t.t.t.wire
      =/  timestamp  `@da`(slav %da i.t.t.wire)
      ?.  =(status-code.-.-.+.+.+.sign-arvo 200)
        :_  this
        :~
          [%pass /failed %agent [`@p`(slav %p src) %file-share] %poke %file-share-failed !>([`@t`i.t.wire timestamp 'get-request'])]
        ==
      ?:  ?=(~ full-file.client-response.sign-arvo)
        `this
      =/  full-file=mime-data:iris  u.full-file.client-response.sign-arvo
      =/  filename  `@t`i.t.wire
      =/  content-type  type.full-file
      =/  body  data.full-file
      =.  filename  (check-filename-duplicate filename state)
      ?<  ?=(~ i.t.t.wire)
      =/  eny  `@t`i.t.t.t.wire
      =/  storage  storage.state
      =.  used.storage  (add used.storage p.body)
      :_  this(state [(~(put by received.state) filename [body content-type src.bowl now.bowl]) sent.state sending.state storage])
      :~
        [%pass /file-received %agent [`@p`(slav %p src) %file-share] %poke %file-share-complete !>([`@t`i.t.wire timestamp now.bowl eny])]
        :*  %pass
          /notify
          %agent
          [our.bowl %hark]
          %poke
          %hark-action
          !>  :*  %add-yarn
                  %.y
                  %.y
                  `@uvH`eny.bowl
                  [~ ~ %file-share /file-share]
                  now.bowl
                  ['Received ' [%emph filename] ' from ' [%ship src.bowl] ~]
                  /[filename]
                  ~
              ==
        ==
      ==
  ==
++  on-fail   on-fail:default
--
