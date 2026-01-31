# Bonsai [盆栽] - Status do Projeto

Este documento resume as funcionalidades atuais do Bonsai Mobile e o roteiro para as próximas integrações.

## ✅ O Que Já Funciona (UI & Mock Logic)

O projeto está com a arquitetura completa e a interface de usuário em padrão premium.

### 1. Interface de Usuário (UX/UI)
- **Tema Premium**: Dark Mode nativo com fontes "Berkeley Mono" e paleta de cores harmoniosa.
- **Dashboard Reativo**: Exibição de saldo em BTC com conversão simulada para USD.
- **Lista de Transações**: Interface de histórico com animação de "pulsação" para novas transações.
- **Navegação**: Fluxo completo entre Dashboard, Send, Receive e Settings.

### 2. Funcionalidades de Envio (Send)
- **Leitor de QR Code**: Integração total com a câmera para escanear endereços Bitcoin.
- **Parsing de URI**: Suporte para o padrão `bitcoin:address?amount=sats`, extraindo automaticamente os dados.
- **Validação de Input**: Campos de endereço e valor com validação básica.

### 3. Funcionalidades de Recebimento (Receive)
- **Geração de QR Code**: Exibição visual do endereço para recebimento.
- **Cópia para Clipboard**: Facilidade para copiar o endereço com um toque.
- **Interface de Labels**: Preparado para rotular endereços (etapa visual).

### 4. Arquitetura de Dados
- **Riverpod**: Gerenciamento de estado global implementado para Saldo e Transações.
- **Repository Pattern**: Uso de `MockWalletRepository` para simular o comportamento de uma carteira real sem precisar de rede durante os testes de UI.
- **Persistence Simulation**: As transações enviadas durante o uso do app persistem na memória durante a sessão.

---

## 🛠️ O Que Está em Planejamento (Ponto de Implementação)

Estas funcionalidades estão com a "casca" pronta no Flutter e aguardam a lógica real no backend Rust.

### 1. Integração BDK (Bitcoin Dev Kit)
- **Carteira Real**: Substituir o `MockWalletRepository` por uma implementação que utiliza o `bdk_wallet` no Rust.
- **Geração de Endereços**: Conectar o botão "Generate New Address" à lógica de derivação de chaves do BDK.

### 2. Sincronização via Floresta (Embedded Node)
- **Utreexo Aware**: O projeto já possui dependências do `bdk-floresta`. O próximo passo é iniciar o nó leve embutido para validar transações sem confiar em servidores centrais.
- **Métricas do Nó**: Popular a tela de "Metrics" com dados reais de sincronização, altura do bloco e peers vindos do Rust.

### 3. Envio Efetivo (Broadcasting)
- **Assinatura de Transações**: Implementar a criação de PSBT (Partially Signed Bitcoin Transactions) e assinatura no Rust.
- **Broadcast**: Enviar a transação assinada para a rede via o nó embutido ou electrum.

### 4. Persistência de Dados
- **Database Local**: Trocar o armazenamento em memória por SQLite ou persistência de arquivo do BDK para manter o histórico entre reinicializações do app.

---

## 🚀 Como Expandir Agora?

O projeto está "no gatilho" para:
1.  **Lógica Rust**: Implementar as funções em `rust/src/wallet` e exportá-las via `api.rs`.
2.  **Stateful UI**: Conectar os carregamentos (loadings) reais às chamadas assíncronas do Rust.
