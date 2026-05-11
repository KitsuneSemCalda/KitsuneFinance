# Fluxo Diário e Dicas - KitsuneFinance 🦊

Agora que seu sistema está turbinado, aqui está como tirar o melhor proveito dele no seu dia a dia.

## 1. Importação Sem Esforço
Em vez de digitar cada cafézinho, reserve 5 minutos por semana para:
*   Baixar o arquivo **OFX** (ou CSV) do seu banco.
*   Ir em **Transações > Importar**.
*   O sistema fará a busca de **CNPJ via BrasilAPI** e categorizará sozinho. 
*   *Dica:* Se uma categoria estiver errada, altere-a manualmente; o sistema lembrará de transações similares no futuro se você adicionar palavras-chave no código.

## 2. Alertas no Celular (ntfy)
Fique atento às notificações push:
*   **Feriados:** O app te avisará às 8h da manhã se houver feriado nacional. Se você tem boletos vencendo, o app te lembrará de pagar antes (ou saber que o banco não processará no dia).
*   **Sucesso de Importação:** Sempre que terminar um upload, você receberá o resumo no celular.

## 3. Consultas Inteligentes
Sempre que uma transação tiver um CNPJ na descrição (comum em PIX de empresas):
*   O app não apenas categoriza, mas você pode ter a certeza de que a categoria é a **oficial da Receita Federal (CNAE)**.

## 4. Manutenção do Servidor (Self-hosted)
*   **Logs:** Se algo não categorizar como deveria, dê uma olhada nos logs do Rails para ver se a BrasilAPI retornou algum erro.
*   **Ambiente:** Mantenha o `NTFY_URL` configurado nas suas variáveis de ambiente para não perder os alertas.

---
*KitsuneFinance: Seu dinheiro, seus dados, seu controle.*
