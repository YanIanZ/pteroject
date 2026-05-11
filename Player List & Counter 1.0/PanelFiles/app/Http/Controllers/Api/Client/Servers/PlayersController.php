<?php

namespace Pterodactyl\Http\Controllers\Api\Client\Servers;

use GameQ\GameQ;
use Pterodactyl\Models\Server;
use Illuminate\Support\Facades\DB;
use Pterodactyl\Classes\MinecraftQuery;
use Pterodactyl\Classes\SourceQuery\SourceQuery;
use Pterodactyl\Classes\Exceptions\MinecraftQueryException;
use Pterodactyl\Http\Controllers\Api\Client\ClientApiController;
use Pterodactyl\Http\Requests\Api\Client\Servers\GetServerRequest;

class PlayersController extends ClientApiController
{
    public function index(GetServerRequest $request, Server $server): array
    {
        $counters = DB::table('player_counter')->get();
        foreach ($counters as $counterItem) {
            if (in_array($server->egg_id, explode(',', $counterItem->egg_ids))) {
                $counter = $counterItem;
            }
        }

        $maxPlayers = 0;
        $onlinePlayers = 0;
        $players = [];

        if (isset($counter)) {
            $allocation = DB::table('allocations')->where('id', '=', $server->allocation_id)->get();
            $ip = $allocation[0]->ip;
            $port = $allocation[0]->port;

            if (in_array($counter->game, ['minecraft'])) {
                $query = null;

                try {
                    $query = new MinecraftQuery($ip, $port, 1);
                    $info = $query->Query();

                    if ($info === false) {
                        $query->Close();
                        $query->Connect();;
                        $query->QueryOldPre17();
                    }

                    $maxPlayers = isset($info['players']['max']) ? $info['players']['max'] : 0;
                    $onlinePlayers = isset($info['players']['online']) ? $info['players']['online'] : 0;

                    if (isset($info['players']['sample'])) {
                        foreach ($info['players']['sample'] as $player) {
                            $players[] = $player['name'];
                        }
                    }
                } catch (MinecraftQueryException $e) {
                    unset($counter);
                } finally {
                    if ($query !== null) {
                        $query->Close();
                    }
                }
            } else if (in_array($counter->game, ['minecraftpe'])) {
                $results = MinecraftQuery::minecraftPE($ip, $port);

                if ($results[0] == 1) {
                    $maxPlayers = isset($results[1]['maxplayers']) ? $results[1]['maxplayers'] : 0;
                    $onlinePlayers = isset($results[1]['numplayers']) ? $results[1]['numplayers'] : 0;
                }
            } else if (in_array($counter->game, ['csgo', 'rust'])) {
                $query = new SourceQuery();

                try {
                    $query->Connect($ip, $port, 1, SourceQuery::SOURCE);
                    $results = $query->GetInfo();

                    $maxPlayers = isset($results['MaxPlayers']) ? $results['MaxPlayers'] : 0;
                    $onlinePlayers = isset($results['Players']) ? $results['Players'] : 0;
                } catch (\Exception $e) {
                    unset($counter);
                } finally {
                    $query->Disconnect();
                }
            } else {
                $GameQ = new GameQ();
                $options = [];

                if (in_array($counter->game, ['arkse', 'bf3', 'sevendaystodie'])) {
                    $options['query_port'] = $port + 1;
                }

                $GameQ->addServer([
                    'type' => $counter->game,
                    'host' => $ip . ':' . $port,
                    'options' => $options,
                ]);

                try {
                    $results = $GameQ->process();

                    $maxPlayers = isset($results[$ip . ':' . $port]['gq_maxplayers']) ? $results[$ip . ':' . $port]['gq_maxplayers'] : 0;
                    $onlinePlayers = isset($results[$ip . ':' . $port]['gq_numplayers']) ? $results[$ip . ':' . $port]['gq_numplayers'] : 0;

                    if (isset($results[$ip . ':' . $port]['players'])) {
                        foreach ($results[$ip . ':' . $port]['players'] as $player) {
                            $players[] = $player['gq_name'];
                        }
                    }
                } catch (\Exception $e) {
                    unset($counter);
                }
            }
        }

        if ($maxPlayers == 0) {
            unset($counter);
        }

        return [
            'success' => true,
            'data' => [
                'show' => isset($counter) ? 1 : 0,
                'maxPlayers' => $maxPlayers,
                'onlinePlayers' => $onlinePlayers,
                'players' => $players,
            ],
        ];
    }
}
