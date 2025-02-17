(herald "UAF using TLS1.2 without channel binding.")

;; In this version, the authenticator is treated as if it is embedded in the client. This is
;; consistent with the FIDO specifications in which they view the authenticator as a part of
;; the client system, such as a finger print reader, camara for facial recognition, TPM, etc.
;; that is used to authenticate the user on the client's system (phone, computer, etc.) that
;; is running the application. In this case there are no protocols that connect to the
;; authenticator, only function calls within the operating system. As we are not evaluating
;; the CTAP protocols, this model provides a better view of the bindings between the client
;; and the server by including the authentication responses directly from the client. This
;; highlights the TLS channel and its relationship to the FIDO authentication protocol. 

(include "TLS1.2_macros.lisp") ; 4 message exchange by combining TLS messages.
(include "UAF_macros.lisp") ; Two message exchange by combining UAF messages.

(defprotocol uaf-unbound-tls12 basic
  ;; Client roles.
  (defrole client-reg
    (vars
      (username auth server ca appid name)
      (challenge text)
      (cr sr random32) ;; TLS nonces. cr: client random, sr: server random
      (pms random48) ;; TLS pre-master secret generated by the client.
      (authk akey) ;; Authenticator's asymmetric key for this registration.
    )
    (trace
      (TLS send recv pms cr sr server ca)
      (UAF_Reg_Unbound_TLS12 send recv username appid challenge auth authk cr sr pms)
    )
  )
  (defrole client-auth
    (vars
      (server ca appid name)
      (challenge text)
      (cr sr random32) ;; TLS nonces. cr: client random, sr: server random
      (pms random48) ;; TLS pre-master secret generated by the client.
      (authk akey)
    )
    (trace
      (TLS send recv pms cr sr server ca)
      (UAF_Auth_Unbound_TLS12 send recv appid challenge authk cr sr pms)
    )
  )
  ;; Server roles.
  (defrole server-reg
    (vars
      (username auth server ca appid name)
      (challenge text)
      (cr sr random32) ;; TLS nonces. cr: client random, sr: server random
      (pms random48) ;; TLS pre-master secret generated by the client.
      (authk akey)
    )
    (trace
      (TLS recv send pms cr sr server ca)
      (UAF_Reg_Unbound_TLS12 recv send username appid challenge auth authk cr sr pms)
    )
  )
  (defrole server-auth
    (vars
      (auth server ca appid name)
      (challenge text)
      (cr sr random32) ;; TLS nonces. cr: client random, sr: server random
      (pms random48) ;; TLS pre-master secret generated by the client.
      (authk akey)
    )
    (trace
      (TLS recv send pms cr sr server ca)
      (UAF_Auth_Unbound_TLS12 recv send appid challenge authk cr sr pms)
    )
  )
  ;; Custom sorts.
  (lang
    (random32 atom)
    (random48 atom)
  )
)

;; Client-reg perspective skeleton.
(defskeleton uaf-unbound-tls12
  (vars
    (server ca name)
    (cr sr random32)
    (pms random48)
    (authk akey)
  )
  (defstrandmax client-reg
    (server server) (ca ca) (cr cr) (pms pms) (authk authk) (sr sr))
  (non-orig (privk ca) (privk server) (invk authk))
  (uniq-orig cr pms)
  (uniq-orig sr) ;; Prevents multiple instances of the same server interacting with the client.
)

;; Client-auth perspective skeleton.
(defskeleton uaf-unbound-tls12
  (vars
    (server ca name)
    (cr sr random32)
    (pms random48)
    (authk akey)
  )
  (defstrandmax client-auth
    (server server) (ca ca) (cr cr) (pms pms) (authk authk) (sr sr))
  (non-orig (privk ca) (privk server) (invk authk))
  (uniq-orig cr pms)
  (uniq-orig sr) ;; Prevents multiple instances of the same server interacting with the client.
)

;; Server-reg perspective skeleton.
(defskeleton uaf-unbound-tls12
  (vars
    (server ca name)
    (sr random32)
    (challenge text)
    (authk akey)
  )
  (defstrandmax server-reg
    (server server) (ca ca) (sr sr) (challenge challenge) (authk authk))
  (non-orig (privk ca) (privk server) (invk authk))
  (uniq-orig challenge sr)
)

;; Server-auth perspective skeleton.
(defskeleton uaf-unbound-tls12
  (vars
    (server ca name)
    (sr random32)
    (challenge text)
    (authk akey)
  )
  (defstrandmax server-auth
    (server server) (ca ca) (sr sr) (challenge challenge) (authk authk))
  (non-orig (privk ca) (privk server) (invk authk))
  (uniq-orig challenge sr)
)

(defgoal uaf-unbound-tls12
  (forall
    ((cr sr random32) (pms random48) (challenge text) (username server ca appid name) (authk akey) (z strd))
    (implies
      (and
        (p "client-reg" z 6)
        (p "client-reg" "cr" z cr)
        (p "client-reg" "sr" z sr)
        (p "client-reg" "pms" z pms)
        (p "client-reg" "challenge" z challenge)
        (p "client-reg" "authk" z authk)
        (p "client-reg" "username" z username)
        (p "client-reg" "server" z server)
        (p "client-reg" "ca" z ca)
        (p "client-reg" "appid" z appid)
        (non (invk authk))
        (non (privk server))
        (non (privk ca))
        (uniq-at cr z 0)
        (uniq-at pms z 2)
        (uniq sr))     
      (exists
        ((z-0 strd))
        (and
          (p "server-reg" z-0 5)
          (p "server-reg" "username" z-0 username)
          (p "server-reg" "challenge" z-0 challenge)
          (p "server-reg" "server" z-0 server)
          (p "server-reg" "appid" z-0 appid))))))

(defgoal uaf-unbound-tls12
  (forall
    ((cr sr random32) (pms random48) (challenge text) (server ca appid name) (authk akey) (z strd))
    (implies
      (and
        (p "client-auth" z 6)
        (p "client-auth" "cr" z cr)
        (p "client-auth" "sr" z sr)
        (p "client-auth" "pms" z pms)
        (p "client-auth" "challenge" z challenge)
        (p "client-auth" "authk" z authk)
        (p "client-auth" "server" z server)
        (p "client-auth" "ca" z ca)
        (p "client-auth" "appid" z appid)
        (non (invk authk))
        (non (privk server))
        (non (privk ca))
        (uniq-at cr z 0)
        (uniq-at pms z 2)
        (uniq sr))     
      (exists
        ((z-0 strd))
        (and
          (p "client-auth" z-0 5)
          (p "client-auth" "challenge" z-0 challenge)
          (p "client-auth" "server" z-0 server)
          (p "client-auth" "appid" z-0 appid))))))

;; Server-reg context agreement.
(defgoal uaf-unbound-tls12
  (forall
    ((sr random32) (challenge text) (username server ca appid name) (authk akey) (z strd))
    (implies
      (and
        (p "server-reg" z 6)
        (p "server-reg" "sr" z sr)
        (p "server-reg" "challenge" z challenge)
        (p "server-reg" "authk" z authk)
        (p "server-reg" "username" z username)
        (p "server-reg" "server" z server)
        (p "server-reg" "ca" z ca)
        (p "server-reg" "appid" z appid)
        (non (invk authk))
        (non (privk server))
        (non (privk ca))
        (uniq-at challenge z 4)
        (uniq-at sr z 1))
      (exists
        ((z-0 strd))
        (and
          (p "client-reg" z-0 6)
          (p "client-reg" "challenge" z-0 challenge)
          (p "client-reg" "username" z username)
          (p "client-reg" "server" z-0 server)
          (p "client-reg" "appid" z-0 appid))))))

;; Server-auth context agreement.
(defgoal uaf-unbound-tls12
  (forall
    ((sr random32) (challenge text) (server ca appid name) (authk akey) (z strd))
    (implies
      (and
        (p "server-auth" z 6)
        (p "server-auth" "sr" z sr)
        (p "server-auth" "challenge" z challenge)
        (p "server-auth" "authk" z authk)
        (p "server-auth" "server" z server)
        (p "server-auth" "ca" z ca)
        (p "server-auth" "appid" z appid)
        (non (invk authk))
        (non (privk server))
        (non (privk ca))
        (uniq-at challenge z 4)
        (uniq-at sr z 1))
      (exists
        ((z-0 strd))
        (and
          (p "client-auth" z-0 6)
          (p "client-auth" "challenge" z-0 challenge)
          (p "client-auth" "server" z-0 server)
          (p "client-auth" "appid" z-0 appid))))))