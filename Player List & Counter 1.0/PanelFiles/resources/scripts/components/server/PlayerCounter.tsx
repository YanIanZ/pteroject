import React, { useEffect } from 'react';
import tw from 'twin.macro';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faUsers } from '@fortawesome/free-solid-svg-icons';
import Spinner from '@/components/elements/Spinner';
import useSWR from 'swr';
import getPlayers from '@/api/server/getPlayers';
import { ServerContext } from '@/state/server';
import useFlash from '@/plugins/useFlash';
import FlashMessageRender from '@/components/FlashMessageRender';
import styled from 'styled-components/macro';

const Code = styled.code`${tw`font-mono py-1 px-2 bg-neutral-900 rounded text-sm inline-block`}`;

export interface PlayersResponse {
    show: number;
    maxPlayers: number;
    onlinePlayers: number;
    players: string[];
}

const PlayerCounter = () => {
    const uuid = ServerContext.useStoreState(state => state.server.data!.uuid);

    const { clearFlashes, clearAndAddHttpError } = useFlash();

    const { data, error } = useSWR<PlayersResponse>([ uuid, '/counter' ], key => getPlayers(key), {
        revalidateOnFocus: true,
        refreshInterval: 10000,
    });

    useEffect(() => {
        if (!error) {
            clearFlashes('server:players');
        } else {
            clearAndAddHttpError({ key: 'server:players', error });
        }
    }, [ error ]);

    return (
        <div css={tw`shadow-md bg-neutral-700 rounded p-3 text-xs mt-4 justify-center text-center`}>
            <div css={tw`w-full`}>
                <FlashMessageRender byKey={'server:players'} css={tw`mb-4`} />
            </div>
            {!data ?
                <Spinner size={'small'} centered />
                :
                <>
                    {data.show === 1 ?
                        <>
                            Players: {data.onlinePlayers}/{data.maxPlayers} <FontAwesomeIcon icon={faUsers} />
                            {data.players.length > 0 ?
                                <div css={tw`w-full mt-4`}>
                                    {data.players.map((item, key) => (
                                        <div key={key} css={tw`mt-2`}>
                                            <Code>{item}</Code>
                                        </div>
                                    ))}
                                </div>
                                :
                                <></>
                            }
                        </>
                        :
                        <>
                            Failed to get online players.
                        </>
                    }
                </>
            }
        </div>
    );
};

export default PlayerCounter;
