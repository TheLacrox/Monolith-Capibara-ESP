armor-plate-break = ¡Tu {$plateName} se ha hecho añicos!
armor-plate-examine-with-plate = Tiene una [color=yellow]{$plateName}[/color] instalada. Durabilidad: [color={$durabilityColor}]{$percent}%[/color]
armor-plate-examine-with-plate-simple = Tiene una [color=yellow]{$plateName}[/color] instalada.
armor-plate-examine-no-plate = No hay placa de armadura instalada.
armor-plate-examine-no-storage = No hay compartimento de almacenamiento para placas de armadura.

armor-plate-examinable-verb-text = Atributos de la placa
armor-plate-examinable-verb-message = Examinar las características de protección y durabilidad.

armor-plate-attributes-examine = Esta placa de armadura:
armor-plate-initial-durability = Está valorada para [color=yellow]{ $durability }[/color] unidades estándar de daño.

armor-plate-item-durability = Durabilidad: [color={$durabilityColor}]{$percent}%[/color]

armor-plate-gait-speed = velocidad
armor-plate-gait-walk = velocidad al caminar
armor-plate-gait-sprint = velocidad al correr

armor-plate-speed-display =
    { $stringClause ->
         [1] Aumenta tu {$gait} en [color=yellow]{$speedPercent}%[/color].
         [-1] Reduce tu {$gait} en [color=yellow]{$speedPercent}%[/color].
        *[other] ¡No debería tener esta cláusula de velocidad!
    }

armor-plate-ratios-display =
    { $stringClause ->
        [1] [color=cyan]Absorbe[/color] el [color=yellow]{$ratioPercent}%[/color] de [color=yellow]{$dmgType}[/color]
        [-1] [color=fuchsia]Amplifica[/color] [color=yellow]{$dmgType}[/color] en un [color=yellow]{$ratioPercent}%[/color]
        [0] No afecta a [color=yellow]{$dmgType}[/color]
       *[other] ¡{$dmgType} no debería tener esta cláusula de absorción!
    }

armor-plate-multiplier-display = y descuenta el [color=yellow]{$multiplier}%[/color] del valor de daño bruto de la durabilidad.
armor-plate-multiplier-none = y no daña la placa.

armor-plate-stamina-source-absorb = [color=cyan]Absorbido[/color]
armor-plate-stamina-concat = y
armor-plate-stamina-source-amplified = [color=fuchsia]Amplificado[/color]
armor-plate-stamina-source-raw = [color=red]Entrante Total[/color]
armor-plate-stamina-value = Inflige el [color=yellow]{$multiplier}%[/color] del daño {$sources} como daño de resistencia.
