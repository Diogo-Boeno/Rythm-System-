# Conventions

Convenções de código que sigo nesse projeto. Quando em dúvida, segue o exemplo
dos arquivos existentes em `src/ServerScriptService/Services/` e `src/StarterPlayerScripts/Controllers/`.

## Naming

| Contexto | Style | Exemplo |
|---|---|---|
| Módulos / Services / Controllers | PascalCase | `PlayerDataService`, `MainMenuController` |
| Type aliases | PascalCase | `DialogNode`, `ItemInstance` |
| Lifecycle methods (`Start`, `Init`) | PascalCase | `function Service:Start()` |
| Signals públicas em módulos | PascalCase | `PlayerService.OnCharacterSpawned` |
| Métodos públicos da API helper de Services | **camelCase** | `addCoins`, `getOwnedAxes`, `setCurrentAxe`, `spendCoins` |
| Variáveis e funções locais | camelCase | `handleCharacter`, `setupRig`, `currentYaw` |
| Constantes module-level | UPPER_SNAKE | `AUTO_CLOSE_DISTANCE`, `IDLE_ANIM_ID`, `NPC_TAG` |
| State module-level | camelCase | `local active`, `local menuRig`, `local activeDialog` |
| Eventos Net | `PascalCase` (sem domínio) | `"BuyAxe"`, `"ShopResult"`, `"OwnedAxesChanged"` |
| Arquivos | PascalCase | `PlayerDataService.luau`, `MainMenuController.luau` |
| Pastas | PascalCase | `Services/`, `Controllers/`, `Modules/`, `UI/` |

## Comentários

**Idioma: inglês.** Comentários explicam **por quê** ou contexto
não-óbvio. Sem comentários redundantes que só repetem o código.

```luau
-- Syncs leaderstats with the profile
local function syncLeaderstats(player, data)
    ...
end

-- Pre-creates remotes on the server so the client never gets stuck in an
-- infinite WaitForChild for "outbound" remotes (which would only be created on the first FireClient).
function Net.Ensure(...)
end
```

Header de arquivo é opcional, mas use pra módulos complexos:

```luau
--!strict
-- Axe shop (server). This is the AUTHORITY for purchases: validates config,
-- ownership and balance before debiting coins and granting the item. The client never decides anything.
```

Formato de TODO:
```luau
-- TODO: descrição
-- DEBUG: print temporário, remover
```

## `--!strict`

Use `--!strict` em arquivos novos quando der. Em arquivos antigos sem strict,
não force a migração — vai aparecendo conforme você refatora.

## Estilo de módulo

**Module-level state, não self-heavy OOP.** O padrão dominante é declarar state
no topo do arquivo como `local` e ter métodos públicos no return table.

```luau
-- Recomendado (estilo do projeto)
local MainMenuController = {}

-- Estado interno do módulo
local active = false
local menuRig: Model? = nil
local menuGui: ScreenGui? = nil

-- Helpers locais
local function setupRig(...) end
local function setupCamera(...) end

-- API pública
function MainMenuController:Start() end
function MainMenuController:Close() end

return MainMenuController
```

Evite OOP com `__index` e `:new()` a menos que você realmente precise de
múltiplas instâncias (raro em Services/Controllers que são singletons).

## Estrutura de arquivo (Service típico)

```luau
--!strict
-- (opcional) Header explicando o papel do módulo em 1-2 linhas
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Dependências locais
local Services = ServerScriptService:WaitForChild("Services")
local Modules = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Modules")
local Framework = ReplicatedStorage.Shared.Framework

local PlayerDataService = require(Services.PlayerDataService)
local Signal = require(Framework.Signal)
local Net = require(Framework.Net)

-- Constantes
local SOMETHING_MAX = 100

-- Módulo
local MyService = {}

-- Signals públicas (PascalCase)
MyService.OnSomething = Signal.new()

-- Helpers locais (camelCase, fora do return table)
local function doInternalThing(player: Player)
    -- ...
end

-- Métodos públicos (camelCase pra helpers da API)
function MyService.addCoins(player: Player, amount: number)
    -- ...
end

-- Lifecycle (PascalCase, com `:`)
function MyService:Start()
    Net.On("MyEvent", function(player, payload)
        -- ...
    end)
end

return MyService
```

Note a mistura intencional:
- `MyService:Start()` — lifecycle, com `:` (passa self)
- `MyService.addCoins(player, ...)` — helper API, com `.` (não usa self, é function-on-module)

Isso é comum no projeto: helpers públicos não usam `self` porque o módulo é singleton.

## Aspas

**Double quotes** por padrão (`"texto"`). Arquivos antigos usam single quotes,
não precisa migrar em massa — só nos arquivos novos. StyLua decide ao formatar.

## Indentação

4 espaços. StyLua cuida disso.

## Patterns recorrentes

### Player join + iterate existing

```luau
function MyService:Start()
    Players.PlayerAdded:Connect(handlePlayer)

    -- Covers players who were already on the server before Start (script reload, etc)
    for _, player in Players:GetPlayers() do
        task.spawn(handlePlayer, player)
    end

    Players.PlayerRemoving:Connect(handlePlayerLeaving)
end
```

### Guard clauses

```luau
function PlayerDataService.addCoins(player, amount)
    local data = PlayerDataService.get(player)
    if not data then return end       -- early return

    data.Coins += amount
    player:SetAttribute("Coins", data.Coins)
    syncLeaderstats(player, data)
end
```

### Server result back to client

```luau
-- server
Net.On("BuyAxe", function(player, axeName)
    if not validar(axeName) then
        Net.FireClient("ShopResult", player, false, "Invalid")
        return
    end
    -- ... compra ...
    Net.FireClient("ShopResult", player, true, "Bought!")
end)
```

### Attributes pra replicação simples

Pra estado de player que outros módulos (incluindo UI) precisam ler, use
`SetAttribute` em vez de criar evento Net dedicado:

```luau
-- server
player:SetAttribute("CurrentAxe", "BronzeAxe")
player:SetAttribute("Coins", 150)

-- client (qualquer Controller)
local axe = player:GetAttribute("CurrentAxe")
player:GetAttributeChangedSignal("Coins"):Connect(function()
    -- reactively updates the UI
end)
```

### Tipos opcionais com `?`

```luau
local menuRig: Model? = nil
local function findAxe(name: string): Model?
    return ReplicatedStorage.Axes:FindFirstChild(name) :: Model?
end
```

## Anti-patterns

- ❌ Comentários em português (código é sempre em inglês; o resto do projeto/docs é PT-BR)
- ❌ `wait()` — use `task.wait()`
- ❌ `Instance.new("RemoteEvent")` direto — sempre Net
- ❌ Funções públicas de Service em PascalCase quando são helpers da API
  (use camelCase: `addCoins`, não `AddCoins`)
- ❌ State em `self.xxx` quando o módulo é singleton — prefira `local xxx` module-level
- ❌ Acessar workspace direto em UI Controller — passe via props ou State/atributo
