# IaC - Infraestrutura como Código para DocEstágio

Este repositório contém scripts de Infraestrutura como Código (IaC) para automatizar a configuração de um ambiente de desenvolvimento para o projeto DocEstágio.

## Sobre o Projeto

O DocEstágio é um sistema em desenvolvimento para gerenciamento de documentos de estágio, utilizando Django como framework principal.

## Requisitos

- Sistema operacional Ubuntu
- Privilégios de root/sudo
- Conexão com internet

## Componentes Instalados

O script configura automaticamente:

- Apache2 como servidor web e proxy reverso
- Python 3 e ambiente virtual (venv)
- Git para controle de versão
- Dependências necessárias para o Django
- Configurações de firewall (ufw)

## Estrutura do Ambiente

- Servidor Web: Apache2
- Aplicação: Django
- Porta HTTP: 80
- Diretório da Aplicação: /opt/docestagio
- Logs: /var/log/apache2/

## Observações

- Este é um ambiente de desenvolvimento/teste
- Não recomendado para produção sem ajustes de segurança adicionais
- Em desenvolvimento ativo, sujeito a alterações

## Status do Projeto

🚧 **Em Desenvolvimento** 
