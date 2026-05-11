import React, { memo, useEffect } from 'react';
import tw from 'twin.macro';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faUsers } from '@fortawesome/free-solid-svg-icons';
import Spinner from '@/components/elements/Spinner';
import useSWR from 'swr';
import getPlayers from '@/api/server/getPlayers';
import useFlash from '@/plugins/useFlash';
import { PlayersResponse } from '@/components/server/PlayerCounter';
import styled from 'styled-components/macro';
import isEqual from 'react-fast-compare';

const IconDescription = styled.p<{ $alarm: boolean }>`
    ${tw`text-sm ml-2`};
    ${props => props.$alarm ? tw`text-white` : tw`text-neutral-400`};
`;

const Icon = memo(styled(FontAwesomeIcon)<{ $alarm: boolean }>`
    ${props => props.$alarm ? tw`text-red-400` : tw`text-neutral-500`};
`, isEqual);

interface Props {
    uuid: string;
}

const PlayerCounter = ({ uuid }: Props) => {
    const { clearFlashes, clearAndAddHttpError } = useFlash();

    const { data, error } = useSWR<PlayersResponse>([ uuid, '/counter/main' ], key => getPlayers(key), {
        revalidateOnFocus: false,
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
        <div css={tw`flex-1 flex md:ml-4 sm:flex hidden justify-center`}>
            {!data ?
                <Spinner size={'small'} centered />
                :
                <>
                    {data.show === 1 ?
                        <>
                            <Icon icon={faUsers} $alarm={false} />
                            <IconDescription $alarm={false}>
                                {data.onlinePlayers}/{data.maxPlayers}
                            </IconDescription>
                        </>
                        :
                        <>
                            <Icon icon={faUsers} $alarm={false} />
                            <IconDescription $alarm={false}>
                                -1/-1
                            </IconDescription>
                        </>
                    }
                </>
            }
        </div>
    );
};

export default PlayerCounter;
