# UI Components (Vide)

Como componentes Vide são escritos no projeto. Padrão extraído de `DialogUI.luau`,
`MainMenu.luau`, e demais componentes em `src/ReplicatedStorage/Shared/UI/`.

## Imports padrão

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local Vide = require(Packages.vide)

local create = Vide.create
local indexes = Vide.indexes
-- (importa source/root/effect só se for usar dentro do componente)
```

## Tipo `Reactive<T>`

Convenção do projeto: props que podem ser estáticas OU reativas usam:

```luau
type Reactive<T> = T | () -> T
```

Cada componente declara isso no topo se precisar.

## Estrutura básica de componente

```luau
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local Vide = require(Packages.vide)

local create = Vide.create

type Reactive<T> = T | () -> T

export type MyComponentProps = {
    label: Reactive<string>,
    onClick: () -> (),
    parent: Instance?,
}

local function MyComponent(props: MyComponentProps)
    return create "TextButton" {
        Size = UDim2.new(0, 152, 0, 36),
        BackgroundColor3 = Color3.fromRGB(45, 45, 45),
        AutoButtonColor = true,
        Text = props.label,
        TextColor3 = Color3.fromRGB(235, 235, 235),
        TextSize = 18,
        FontFace = Font.new(
            "rbxasset://fonts/families/GothamSSm.json",
            Enum.FontWeight.SemiBold
        ),
        Parent = props.parent,

        Activated = function()
            props.onClick()
        end,

        create "UICorner" { CornerRadius = UDim.new(0, 6) },
        create "UIStroke" {
            Color = Color3.fromRGB(17, 17, 17),
            Thickness = 2,
        },
    }
end

return MyComponent
```

## Sintaxe `create "ClassName" { ... }`

O projeto usa a sintaxe call-as-string do Lua, **sem parênteses**:

```luau
-- Recomendado (estilo do projeto)
create "Frame" {
    Size = UDim2.new(...),
    BackgroundColor3 = Color3.fromRGB(...),
}

-- Não usado (válido, mas inconsistente com o resto)
create("Frame")({ Size = ..., BackgroundColor3 = ... })
```

## Events

Eventos vão **direto** no objeto de props, sem wrapper:

```luau
create "TextButton" {
    Activated = function()
        props.onClick()
    end,

    MouseEnter = function()
        isHovered(true)
    end,

    MouseLeave = function()
        isHovered(false)
    end,
}
```

## Props reativas (estática ou source)

Vide aceita valor estático OU função (source) na mesma posição:

```luau
create "TextLabel" {
    -- Estático
    Text = "{`ProjectName`}",

    -- Reativo: passa a source diretamente
    Text = npcName,

    -- Reativo: passa uma função
    Text = function()
        return `{name()} — Lv {level()}`
    end,
}
```

## State local com `source`

Pra hover, toggle, etc. dentro do componente:

```luau
local source = Vide.source

local function Button(props)
    local isHovered = source(false)

    return create "TextButton" {
        BackgroundColor3 = function()
            return if isHovered()
                then Color3.fromRGB(60, 60, 60)
                else Color3.fromRGB(45, 45, 45)
        end,

        MouseEnter = function() isHovered(true) end,
        MouseLeave = function() isHovered(false) end,
    }
end
```

## Listas dinâmicas com `indexes`

`indexes(source, renderFn)` cria/destrói filhos conforme a tabela muda:

```luau
local indexes = Vide.indexes

create "Frame" {
    create "UIListLayout" { Padding = UDim.new(0, 6) },

    indexes(props.options, function(option, index)
        return OptionButton(option, index, props.onSelect)
    end),
}
```

`option` aqui é uma source — leia com `option()` dentro de render functions.

## Mount no Controller

Componentes não montam sozinhos. O Controller mounta usando `root()`:

```luau
local Vide = require(Packages.vide)
local root = Vide.root

function MyController:Start()
    local gui = Instance.new("ScreenGui")
    gui.Parent = playerGui

    root(function()
        MyComponent {
            parent = gui,
            label = "Hello",
            onClick = function() print("clicked") end,
        }
    end)
end
```

Pra cleanup correto, guarda o retorno de `root()`:

```luau
local cleanup = root(function()
    return MyComponent { ... }
end)

-- depois:
cleanup()    -- desmonta efeitos reativos
```

`gui:Destroy()` cuida das instâncias Roblox, mas `cleanup()` desconecta os
effects reativos do Vide (importante pra evitar memory leak).

## Componentes do design system

Componentes que devem existir (alguns já existem em `Shared/UI/`):

- **MainMenu** ✅ — tela inicial brutalist
- **DialogUI** ✅ — bubble de diálogo de NPC
- **HealthBar** ✅ — barra de vida genérica
- **TreeHealthBar** ✅ — barra adornada em árvore quando damaged
- **Merchant**, **SellShop**, **Inventory** ✅ — telas de comércio
- **Pop** ✅ — notification/toast
- **CornerBrackets** — wrapper de modal com brackets nos cantos (a fazer)
- **Button** ✅ — estados idle/hover/press/disabled via Theme
- **StatBar** — barra de progress genérica (durability, XP) (a fazer)
- **SectionLabel** — `[ STORAGE ]` header de seção (a fazer)

Quando criar componente novo, segue este pattern e cria a story
correspondente em `ReplicatedStorage/Stories/Common/` (mesma sub-pasta que
o componente tem em `Shared/UI/Common/` — UI Labs agrupa pela árvore de pastas).

## Story pattern (UI Labs)

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local Vide = require(Packages.vide)
local MyComponent = require(ReplicatedStorage.Shared.UI.MyComponent)

local source = Vide.source

return {
    vide = Vide,
    controls = {
        label = "Click me",
    },
    story = function(props)
        return MyComponent {
            parent = props.target,
            label = props.controls.label,
            onClick = function() print("[Story] click") end,
        }
    end,
}
```

`props.target` é a Instance fornecida pelo UI Labs onde a story renderiza.
`props.controls` reflete os controls definidos no return.

## Regras

- Componente recebe `parent` via props, **não usa `gui:WaitForChild`** nem
  acessa game state direto
- Props sempre com `export type` no topo do arquivo
- Cores hardcoded como `Color3.fromRGB(...)` — sem theme module por enquanto
- Use `Reactive<T>` pra props que podem mudar após mount
- Lifecycle de cleanup é responsabilidade do Controller que monta, não do componente

## Anti-patterns

- ❌ Sintaxe `create("Frame")({...})` — usa `create "Frame" { ... }`
- ❌ `[Vide.Event("Activated")] = ...` — usa `Activated = ...` direto
- ❌ Acessar `game:GetService(...)` dentro do componente — passa via props
- ❌ Acessar State module ou Attributes direto — passa via props (source ou função)
- ❌ Componente cuidando do próprio cleanup — Controller cuida disso via `root`
