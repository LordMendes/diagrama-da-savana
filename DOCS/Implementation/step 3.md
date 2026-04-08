# Step 3 — Autenticação backend (Pow ou Guardian + email)

**Depende de:** `step 2.1.md` concluído  
**Pode rodar em paralelo com:** `step 2.2.md` (se 2.1 já terminou antes de 2.2)  
**Desbloqueia:** `step 4.1.md`, `step 4.2.md`, `step 5.md`

## Objetivo

Implementar cadastro (email + senha), login, esqueci minha senha com email (Bamboo ou Swoosh), hash de senha (Comeonin/Bcrypt), e proteção de rotas/API privadas conforme CONCEPT.md. Em **desenvolvimento local**, emails devem ser exercitados com **MailHog** no Docker Compose (SMTP de captura + UI web), conforme `DOCS/Implementation/AGENT-WORKFLOW.md`.

## Prompt para o agente (copiar e colar)

```
Implemente a autenticação no backend Phoenix do "Diagrama da Savana" conforme DOCS/Implementation/CONCEPT.md.

Escopo — Step 3:
- Escolher Pow ou Guardian + estratégia de sessão/token alinhada ao frontend (JSON API ou cookie, documentar).
- Sign up, sign in, logout; forgot password com token e email de redefinição (Bamboo ou Swoosh + adapter de dev/test).
- **MailHog** (ou equivalente) no **docker-compose** para dev local: serviço SMTP (ex. porta 1025) e UI (ex. porta 8025); configurar Swoosh/Bamboo para enviar para MailHog em `dev`; documentar URL da UI e variáveis em `.env.example` (com comentários segredo vs público, ver regras do projeto).
- Mensagens de erro da API preparadas para exibição em pt-BR no cliente (corpo ou código mapeável).
- Testes ExUnit para fluxos críticos (registro, login, token de reset inválido).
- Variáveis de ambiente para SMTP ou adapter de email (produção vs MailHog em dev).

Não implemente telas React (steps 4.x). Ao terminar, marque a checklist em DOCS/Implementation/step 3.md.
```

## Lista de tarefas (atualizar ao concluir)

- [x] Usuário e credenciais persistidos com segurança
- [x] Login, cadastro e logout funcionando via API
- [x] Fluxo esqueci minha senha + email (dev/test documentado)
- [x] **MailHog** (ou equivalente) no docker-compose + SMTP configurado para dev local; README com como abrir a UI e testar o fluxo de email
- [x] Rotas privadas protegidas
- [x] Testes ExUnit cobrindo fluxos principais
- [x] Checklist deste arquivo atualizada

### Notas de implementação

- **Autenticação:** API JSON com **Guardian** (JWT no header `Authorization: Bearer …`), **Bcrypt** para senha e **Swoosh** para e-mail. **Pow** não está no Hex compatível com Phoenix 1.8.x; a alternativa Guardian + fluxo próprio atende ao escopo (sign up / sign in / logout / reset por e-mail).
- **Rotas:** prefixo `/api/v1` — ver `backend/README.md` (tabela e MailHog).
