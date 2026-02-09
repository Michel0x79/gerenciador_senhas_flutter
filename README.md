# 🔐 Gerenciador de Senhas Flutter

Um aplicativo completo e seguro para gerenciar suas senhas, desenvolvido em Flutter.

## ✨ Funcionalidades

### 🔒 Segurança
- **Criptografia AES**: Todas as senhas são criptografadas usando AES-256
- **Banco de dados local SQLite**: Armazenamento seguro offline
- **Senha mestra**: Proteção de acesso ao aplicativo
- **Autenticação biométrica**: Suporte para digital/face (opcional)
- **Hashing SHA-256**: Senha mestra armazenada com hash seguro

### 📝 CRUD Completo
- ✅ Criar novas entradas de senha
- 📖 Visualizar lista de senhas
- ✏️ Editar senhas existentes
- 🗑️ Excluir senhas

### 🎲 Gerador de Senhas
- Configuração de tamanho (4-32 caracteres)
- Opções personalizáveis:
  - Letras maiúsculas (A-Z)
  - Letras minúsculas (a-z)
  - Números (0-9)
  - Caracteres especiais (!@#$%...)
- Geração segura usando Random.secure()

### 💡 Recursos Extras
- 👁️ Mostrar/ocultar senhas
- 📋 Copiar senha para área de transferência
- 🎨 Interface moderna e intuitiva
- 📱 Responsivo e otimizado
- ⚡ Feedback visual para todas as ações

## 🚀 Como Executar

### Pré-requisitos
- Flutter SDK (>=3.0.0)
- Android Studio / VS Code
- Dispositivo Android/iOS ou emulador

### Instalação

1. Clone ou extraia o projeto
2. Instale as dependências:
```bash
flutter pub get
```

3. Execute o aplicativo:
```bash
flutter run
```

## 📦 Dependências Principais
```yaml
dependencies:
  sqflite: ^2.3.0              # Banco de dados SQLite
  encrypt: ^5.0.3               # Criptografia AES
  provider: ^6.1.1              # Gerenciamento de estado
  local_auth: ^2.1.7            # Autenticação biométrica
  flutter_secure_storage: ^9.0.0 # Armazenamento seguro
  crypto: ^3.0.3                # Funções criptográficas
```

## 🏗️ Arquitetura
```
lib/
├── main.dart                 # Ponto de entrada
├── models/
│   └── password_entry.dart   # Modelo de dados
├── providers/
│   └── password_provider.dart # Estado da aplicação
├── screens/
│   ├── auth_screen.dart      # Tela de autenticação
│   ├── home_screen.dart      # Tela principal
│   ├── password_form_screen.dart # Formulário CRUD
│   ├── password_generator_screen.dart # Gerador
│   └── settings_screen.dart  # Configurações
└── services/
    ├── database_service.dart     # SQLite
    ├── encryption_service.dart   # Criptografia
    ├── auth_service.dart         # Autenticação
    └── password_generator_service.dart # Gerador
```

## 🔐 Segurança

### Criptografia
- **Algoritmo**: AES-256 em modo CBC
- **Derivação de chave**: SHA-256 da senha mestra
- **IV (Initialization Vector)**: 16 bytes

### Armazenamento
- **Senhas**: Criptografadas no SQLite
- **Senha mestra**: Hash SHA-256 no Secure Storage
- **Dados locais**: Nunca enviados para a nuvem

## 📱 Recursos do Sistema

### Android
Adicione ao `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
```

### iOS
Adicione ao `Info.plist`:
```xml
<key>NSFaceIDUsageDescription</key>
<string>Autenticação para acessar suas senhas</string>
```

## 🎯 Uso

1. **Primeira vez**: Crie uma senha mestra forte
2. **Adicionar senha**: Toque no botão + e preencha os campos
3. **Visualizar senha**: Toque no item e clique no ícone de olho
4. **Copiar senha**: Use o ícone de copiar
5. **Gerar senha**: Acesse o gerador pelo menu superior
6. **Configurações**: Ative a biometria para acesso rápido

## ⚠️ Avisos Importantes

- **Não perca sua senha mestra**: Não há recuperação possível
- **Faça backups**: Considere exportar periodicamente
- **Mantenha atualizado**: Use sempre a versão mais recente

## 🛠️ Melhorias Futuras

- [ ] Exportar/Importar senhas (criptografado)
- [ ] Categorias/Tags para organização
- [ ] Pesquisa e filtros
- [ ] Histórico de alterações
- [ ] Avaliação de força de senha
- [ ] Auto-preenchimento (autofill)
- [ ] Sincronização em nuvem (opcional)
- [ ] Modo escuro

## 📄 Licença

Este projeto é de código aberto para fins educacionais.

## 👨‍💻 Desenvolvimento

Desenvolvido com ❤️ usando Flutter e Dart.