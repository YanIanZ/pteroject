import http from '@/api/http';
import { PlayersResponse } from '@/components/server/PlayerCounter';

export default async (uuid: string): Promise<PlayersResponse> => {
    const { data } = await http.get(`/api/client/servers/${uuid}/players`);

    return (data.data || []);
};
