using System.Text.RegularExpressions;
using Content.Shared._Crescent.SpaceBiomes;
using Robust.Shared.Prototypes;
using Content.Client.Audio;
using Robust.Client.Graphics;
using Robust.Shared.Timing;
using Content.Shared._Crescent.Vessel;

namespace Content.Client._Crescent.SpaceBiomes;

public sealed partial class SpaceTextDisplaySystem : EntitySystem
{
    [Dependency] private IPrototypeManager _protMan = default!;
    [Dependency] private IOverlayManager _overMan = default!;
    [Dependency] private ContentAudioSystem _audioSys = default!;

    private SpaceBiomeTextOverlay _overlay = default!;

    public override void Initialize()
    {
        base.Initialize();
        SubscribeLocalEvent<SpaceBiomeSwapMessage>(OnSwap);
        SubscribeLocalEvent<PlayerParentChangedMessage>(OnNewVesselEntered);
        _overlay = new();
        _overMan.AddOverlay(_overlay);
    }

    private void OnSwap(ref SpaceBiomeSwapMessage ev)
    {
        _audioSys.DisableAmbientMusic();
        SpaceBiomePrototype biome = _protMan.Index<SpaceBiomePrototype>(ev.Id);
        _overlay.Reset();
        _overlay.ResetDescription();
        // Capibara ESP: biome names/descriptions are raw strings in YAML with no upstream
        // Loc hook; look up an additive locale override first. KEEP OURS on merge conflict.
        var name = Loc.TryGetString($"space-biome-{biome.ID}-name", out var locName) ? locName : biome.Name;
        var description = Loc.TryGetString($"space-biome-{biome.ID}-desc", out var locDesc) ? locDesc : biome.Description;
        _overlay.Text = name;
        _overlay.TextDescription = description;
        _overlay.CharInterval = TimeSpan.FromSeconds(2f / name.Length);
        if (_overlay.TextDescription == "")                   //if we have a biome with no description, it's default is "" and that has length 0.
            _overlay.CharIntervalDescription = TimeSpan.Zero;       //we need to calculate it here because otherwise...
        else
            _overlay.CharIntervalDescription = TimeSpan.FromSeconds(2f / description.Length);      //this would throw an exception
        // End Capibara ESP
    }

    private void OnNewVesselEntered(ref PlayerParentChangedMessage ev)
    {
        if (ev.Grid == null) //player walked into space so we dont care
            return;

        var name = MetaData((EntityUid)ev.Grid).EntityName; //this should never be null. i hope
        var description = ""; //fallback for description is nothin'
        if (TryComp<VesselInfoComponent>((EntityUid)ev.Grid, out var vesselinfo))
            description = vesselinfo.Description;

        // Capibara ESP: grid names and vessel descriptions are raw strings from map/prototype
        // YAML with no upstream Loc hook; look up additive es-ES overrides keyed on a slug of
        // the English grid name (see es-ES/_Capibara/vessels.ftl). Purchased ships append a
        // hull number to the name template ("Eris PDV3"), so the description key strips
        // trailing digits to match per ship class. KEEP OURS on merge conflict.
        var nameKey = $"vessel-{Slugify(name)}-name";
        var descKey = $"vessel-{Slugify(HullNumber.Replace(name, ""))}-desc";
        if (Loc.TryGetString(nameKey, out var locName))
            name = locName;
        if (description.Length > 0 && Loc.TryGetString(descKey, out var locDesc))
            description = locDesc;
        // End Capibara ESP


        _overlay.Reset();             //these should be reset as well to match OnSwap
        _overlay.ResetDescription();

        if (_overlay.Text != null)
            return;

        if (name.Length == 0)
            return;

        _overlay.Text = name;
        _overlay.TextDescription = description; // fallback is "" if no description is found.
        _overlay.CharInterval = TimeSpan.FromSeconds(2f / _overlay.Text.Length);

        if (_overlay.TextDescription == "")
            _overlay.CharIntervalDescription = TimeSpan.Zero; //if this is not done it tries dividing by 0 in the "else" clause
        else
            _overlay.CharIntervalDescription = TimeSpan.FromSeconds(2f / _overlay.TextDescription.Length);
    }

    // Capibara ESP: helpers for the additive vessel locale lookup above.
    // Plain `new Regex(...)` — NOT [GeneratedRegex]: the source generator emits code that
    // touches Regex internals/SearchValues, which the client content sandbox forbids
    // (res.typecheck aborts client startup). Mirrors ContentLocalizationManager.PluralEsRule.
    private static readonly Regex NonAlphanumeric = new("[^a-z0-9]+");
    private static readonly Regex HullNumber = new(@"\d+\s*$");

    private static string Slugify(string name)
    {
        return NonAlphanumeric.Replace(name.ToLowerInvariant(), "-").Trim('-');
    }
    // End Capibara ESP
}
