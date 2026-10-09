# EASYSELL

Projeto organizado para o Flutter e o backend do projeto Web compartilharem a mesma API e o mesmo banco MongoDB.

## Estrutura

- `frontend/` — aplicativo Flutter
- `backend/` — backend NestJS usado pelo Web e pelo Flutter

## Backend

1. Entre em `backend`.
2. Copie `.env.example` para `.env`.
3. Configure `MONGODB_URI` e `JWT_SECRET`.
4. Execute:

```powershell
npm.cmd install
npm.cmd run start:dev
```

API: `http://localhost:3000`

## Flutter

Entre em `frontend` e execute:

```powershell
flutter pub get
flutter run -d chrome
```

O Flutter usa `http://localhost:3000` no Chrome e `http://10.0.2.2:3000` no Android Emulator.

## Dados compartilhados

O Flutter foi adaptado para consumir as entidades do backend existente:

- autenticação: `/auth/login` e `/auth/me`
- usuários: `/user`
- empresas: `/company`
- produtos: `/produtos`
- vendas: `/clientes`
- equipe: `/company/employees`

O cadastro cria o usuário e inicializa uma empresa vinculada a ele. Produtos, vendas e funcionários são gravados no MongoDB e filtrados pela empresa do usuário.
"# PROJETO_EASYSELL_FLUTTER" 
