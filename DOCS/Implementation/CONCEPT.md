Aqui está o **prompt completo e pronto para usar** (copie e cole diretamente em um AI como Claude, Grok, Cursor, etc.) para gerar a implementação da web app:

---

**Crie uma aplicação web full-stack completa chamada "Diagrama da Savana".**

É uma ferramenta de alocação e rebalanceamento de carteira inspirada no conceito brasileiro de investimentos resilientes (sem copiar nome ou marca de nenhuma ferramenta proprietária). O nome oficial é **Diagrama da Savana** e todo o sistema deve ser 100% em português brasileiro (pt-BR), com linguagem clara, natural e amigável para investidores brasileiros.

### Stack Técnica (obrigatória)
- **Frontend**: React 18+ (com TypeScript) + Vite + Tailwind CSS + shadcn/ui + React Router + TanStack Query (React Query). Deve ser **totalmente responsivo** (mobile-first).
- **Backend**: Elixir + Phoenix Framework (última versão estável) + Ecto + PostgreSQL.
- **Autenticação**: Use Phoenix + Pow ou Guardian + Comeonin/Bcrypt. Deve ter:
  - Cadastro (sign up) com email + senha.
  - Login.
  - Esqueci minha senha (forgot password) com link de redefinição via email (use Bamboo ou Swoosh para envio).
  - Proteção de todas as rotas privadas.
- **Banco de dados**: PostgreSQL (use Ecto schemas).
- **API de dados financeiros**: Use a API gratuita **brapi.dev** (https://brapi.dev) para:
  - Busca de tickers com autocomplete (ações, FIIs e ETFs brasileiros).
  - Cotação atual (quote).
  - Histórico simples quando necessário.
  - Endpoint de busca deve ter debounce e autocomplete bonito no frontend.

### Funcionalidades Principais (implementar todas)

1. **Autenticação e Onboarding**
   - Página inicial pública com login/cadastro.
   - Após login: dashboard pessoal.

2. **Dashboard**
   - Visão geral da carteira (valor total, % alocado por classe, variação diária via brapi).
   - Gráfico de pizza simples das classes de ativos.
   - Lista de aportes recentes e sugestão do próximo aporte.

3. **Gestão de Carteira**
   - Definir % alvo por classe macro (Renda Fixa, Renda Variável/Ações, FIIs, Internacional, Cripto, etc.). O usuário pode editar esses targets.
   - Adicionar ativos à carteira (ticker via busca com autocomplete + brapi).
   - Armazenar: quantidade de cotas/ações, preço médio de compra.

4. **Diagrama da Savana – Nota de Resistência (Scoring)**
   - Para cada ativo (ação ou FII), o usuário preenche um checklist de critérios para calcular a **Nota de Resistência** (de -5 a +10).
   - Critérios separados por tipo:
     - **Ações**: Perenidade do negócio, Governança, Dividendos consistentes (>4 anos), Margens, Dívida, Moat, etc.
     - **FIIs**: Localização nobre, P/VP < 1.0, Yield acima da média, Diversificação de locatários, Idade do fundo, etc.
   - Interface tipo formulário com +1 / -1 por critério. Resultado final é a "Nota de Resistência".
   - Ativos com nota ≤ 0 são automaticamente excluídos de qualquer alocação.

5. **Calculadora de Aporte e Rebalanceamento (coração da ferramenta)**
   - Usuário informa o valor do novo aporte (ex: R$ 5.000).
   - O sistema executa em duas camadas:
     - **Camada Macro**: calcula o "gap" de cada classe em relação ao target e distribui o aporte prioritariamente para as classes mais defasadas (ignorando classes no target ou acima).
     - **Camada Micro**: dentro de cada classe, distribui o valor proporcionalmente à Nota de Resistência dos ativos aprovados (quanto maior a nota, maior a fatia). Usa cotação atual da brapi para calcular quantidade exata de cotas a comprar.
   - Resultado claro e acionável:
     - "Com R$ 5.000, aloque R$ X em RV: compre 12 cotas de PETR4 e 45 cotas de KNRI11"
   - Botão "Aplicar no portfólio" que atualiza as quantidades (opcional).

6. **Outras telas**
   - Biblioteca de Ativos: busca com autocomplete + filtro por tipo (ação/FII) + visualização da nota de resistência já calculada.
   - Histórico de aportes e rebalanceamentos.
   - Perfil do usuário (editar dados, logout).

### Requisitos Técnicos Adicionais
- Toda a interface em **português brasileiro** (botões, labels, mensagens de erro, tooltips, etc.).
- Design clean, moderno, verde/savana (tons de verde, terra e laranja sutil) para combinar com o nome "Diagrama da Savana".
- Totalmente responsivo (funciona perfeitamente no celular).
- Tratamento de loading, erros e mensagens amigáveis.
- Rate limiting e cache básico no backend para chamadas à brapi.dev (respeitar limites do plano gratuito).
- Use environment variables para chaves (API brapi, database, email, etc.).
- Estrutura de pastas clara (Phoenix padrão + frontend separado ou monorepo).

Gere o código completo com:
- Estrutura de pastas.
- Schemas do banco (User, Portfolio, Asset, Holding, ResistanceScore, TargetAllocation).
- Controllers e LiveViews ou JSON API (escolha o que for mais adequado).
- Componentes React principais.
- Instruções de como rodar (docker-compose com Phoenix + Postgres + frontend).

Comece gerando primeiro a arquitetura completa e depois o código backend + frontend passo a passo.

---

Esse prompt é bem detalhado, direto e otimizado para que o AI gere um projeto funcional e profissional. Se quiser alguma ajuste (ex: mudar o nome para outro, adicionar mais features, ou usar Next.js em vez de Vite), é só falar!