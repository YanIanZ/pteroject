<?php

namespace Pterodactyl\Http\Controllers\Admin;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\RedirectResponse;
use Prologue\Alerts\AlertsMessageBag;
use Pterodactyl\Exceptions\DisplayException;
use Pterodactyl\Http\Controllers\Controller;

class PlayerCounterController extends Controller
{
    /**
     * @var \Prologue\Alerts\AlertsMessageBag
     */
    protected $alert;

    /**
     * @var array
     */
    protected $games = [
        'minecraft' => 'Minecraft',
        'minecraftpe' => 'Minecraft:PE',
        'csgo' => 'Counter Strike: Global Offensive',
        'cs16' => 'Counter Strike 1.6',
        'css' => 'Counter Strike Source',
        'gmod' => 'Garry\'s Mod',
        'insurgency' => 'Insurgency',
        'insurgencysand' => 'Insurgency: Sandstorm',
        'tf2' => 'Team Fortress 2',
        'mta' => 'Multi Theft Auto',
        'samp' => 'San Andreas Multiplayer',
        'gta5m' => 'Five:M',
        'cod2' => 'Call of Duty 2',
        'cod4' => 'Call of Duty 4',
        'unturned' => 'Unturned',
        'l4d2' => 'Left 4 Dead 2',
        'arma3' => 'Arma 3',
        'mordhau' => 'Mordhau',
        'rust' => 'Rust',
        'hurtworld' => 'Hurtworld',
        'hl2dm' => 'Half Life',
        'conanexiles' => 'Conan Exiles',
        'sevendaystodie' => 'Seven Days to Die (+1 port required)',
        'arkse' => 'Ark Survival Evolved (+1 port required)',
        'bf3' => 'Battlefield 3 (+1 port required)',
        'mumble' => 'Mumble',
    ];

    /**
     * PlayerCounterController constructor.
     * @param AlertsMessageBag $alert
     */
    public function __construct(AlertsMessageBag $alert)
    {
        $this->alert = $alert;
    }

    /**
     * @return \Illuminate\Contracts\View\Factory|\Illuminate\View\View
     */
    public function index()
    {
        $counters = DB::table('player_counter')->get();
        $eggs = DB::table('eggs')->select(['id', 'name'])->get();

        foreach ($counters as $key => $counter) {
            $egg_names = '';

            foreach ($eggs as $egg) {
                if (in_array($egg->id, explode(',', $counter->egg_ids))) {
                    $egg_names .= str_replace(' ', '-', $egg->name) . ' ';
                }
            }

            $counters[$key]->eggs = str_replace('-', ' ', str_replace(' ', ', ', trim($egg_names)));
            $counters[$key]->game_name = $this->games[$counter->game];
        }

        return view('admin.players', [
            'counters' => $counters,
            'eggs' => $eggs,
            'games' => $this->games,
        ]);
    }

    /**
     * @param Request $request
     * @return RedirectResponse
     * @throws DisplayException
     * @throws \Illuminate\Validation\ValidationException
     */
    public function create(Request $request)
    {
        $this->validate($request, [
            'egg_ids' => 'required',
            'game' => 'required',
        ]);

        $egg_ids = $request->input('egg_ids', []);
        $game = trim(strip_tags($request->input('game')));

        foreach ($egg_ids as $egg_id) {
            $eggExists = DB::table('eggs')->where('id', '=', $egg_id)->get();
            if (count($eggExists) < 1) {
                throw new DisplayException('Egg not found.');
            }

            $others = DB::table('player_counter')->get();
            foreach ($others as $other) {
                if (in_array($egg_id, explode(',', $other->egg_ids))) {
                    throw new DisplayException('You\'ve already set this egg to other counter: ' . $eggExists[0]->name);
                }
            }
        }

        if (!isset($this->games[$game])) {
            throw new DisplayException('Invalid game.');
        }

        DB::table('player_counter')->insert([
            'egg_ids' => implode(',', $egg_ids),
            'game' => $game,
        ]);

        $this->alert->success('You have successfully created new counter.')->flash();

        return redirect()->route('admin.players');
    }

    /**
     * @param Request $request
     * @return RedirectResponse
     * @throws DisplayException
     * @throws 270 \Illuminate\Validation\ValidationException
     */
    public function update(Request $request)
    {
        $this->validate($request, [
            'counter_id' => 'required|integer',
            'egg_ids' => 'required',
            'game' => 'required',
        ]);

        $counter_id = $request->input('counter_id', 0);

        $counter = DB::table('player_counter')->where('id', '=', $counter_id)->get();
        if (count($counter) < 1) {
            throw new DisplayException('Mod not found.');
        }

        $egg_ids = $request->input('egg_ids', []);
        $game = trim(strip_tags($request->input('game')));

        foreach ($egg_ids as $egg_id) {
            $eggExists = DB::table('eggs')->where('id', '=', $egg_id)->get();
            if (count($eggExists) < 1) {
                throw new DisplayException('Egg not found.');
            }

            $others = DB::table('player_counter')->where('id', '!=', $counter_id)->get();
            foreach ($others as $other) {
                if (in_array($egg_id, explode(',', $other->egg_ids))) {
                    throw new DisplayException('You\'ve already set this egg to other counter.' . $eggExists[0]->name);
                }
            }
        }

        if (!isset($this->games[$game])) {
            throw new DisplayException('Invalid game.');
        }

        DB::table('player_counter')->where('id', '=', $counter_id)->update([
            'egg_ids' => implode(',', $egg_ids),
            'game' => $game,
        ]);

        $this->alert->success('You have successfully edited this counter.')->flash();

        return redirect()->route('admin.players');
    }

    /**
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function delete(Request $request)
    {
        $counter_id = (int) $request->input('id', '');

        $counter = DB::table('player_counter')->where('id', '=', $counter_id)->get();
        if (count($counter) < 1) {
            return response()->json(['error' => 'Counter not found.'])->setStatusCode(500);
        }

        DB::table('player_counter')->where('id', '=', $counter_id)->delete();

        return response()->json(['success' => true]);
    }
}
