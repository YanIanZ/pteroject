@extends('layouts.admin')

@section('title')
    Player Counter
@endsection

@section('content-header')
    <h1>Player Counter<small>Set counter protocols to eggs.</small></h1>
    <ol class="breadcrumb">
        <li><a href="{{ route('admin.index') }}">Admin</a></li>
        <li class="active">Player Counter</li>
    </ol>
@endsection

@section('content')
    <div class="row">
        <div class="col-xs-12 col-md-8">
            <div class="box box-primary">
                <div class="box-header with-border">
                    <h3 class="box-title">Counters</h3>
                </div>
                <div class="box-body table-responsive no-padding">
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th>#</th>
                                <th>Egg(s)</th>
                                <th>Game</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach ($counters as $counter)
                                <tr>
                                    <td>{{ $counter->id }}</td>
                                    <td>
                                        <span class="label label-info" data-toggle="tooltip" data-placement="top" data-container="body" title="{{ $counter->eggs }}">
                                            Show
                                        </span>
                                    </td>
                                    <td>{{ $counter->game_name }}</td>
                                    <td>
                                        <button class="btn btn-primary btn-xs" onclick="edit({{ $counter->id }});">
                                            <i class="fa fa-pencil"></i>
                                        </button>
                                        <button class="btn btn-danger btn-xs" data-action="delete" data-id="{{ $counter->id }}">
                                            <i class="fa fa-trash"></i>
                                        </button>
                                    </td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
        <div class="col-xs-12 col-md-4">
            <div class="box box-info">
                <div class="box-header with-border">
                    <h3 class="box-title">Info</h3>
                </div>
                <div class="box-body">
                    Some games <b>require</b> an extra opened port. Check it in
                    <a href="https://github.com/Austinb/GameQ/wiki/Supported-servers-list-v2" target="_blank">this</a>
                    site.
                </div>
            </div>
            <div class="box box-success" id="createBox" {!! old('counter_id', 0) == 0 ? '' : 'style="display: none;"' !!}>
                <div class="box-header with-border">
                    <h3 class="box-title">Create Counter</h3>
                </div>
                <form method="post" action="{{ route('admin.players.create') }}">
                    <div class="box-body">
                        <div class="form-group">
                            <label for="egg_ids">Egg(s)</label>
                            <select id="egg_ids" name="egg_ids[]" multiple class="form-control egg_ids">
                                @foreach ($eggs as $egg)
                                    <option value="{{ $egg->id }}" {{ in_array($egg->id, old('egg_ids', [])) ? 'selected' : '' }}>{{ $egg->name }}</option>
                                @endforeach
                            </select>
                        </div>
                        <div class="form-group">
                            <label for="game">Game</label>
                            <select id="game" name="game" class="form-control game">
                                @foreach ($games as $key => $game)
                                    <option value="{{ $key }}" {{ $key == old('game', '') ? 'selected' : '' }}>{{ $game }}</option>
                                @endforeach
                            </select>
                        </div>
                    </div>
                    <div class="box-footer">
                        {!! csrf_field() !!}
                        <button class="btn btn-success pull-right btn-sm">Create</button>
                    </div>
                </form>
            </div>
            @foreach ($counters as $counter)
                <div class="box box-warning editBox" id="editBox-{{ $counter->id }}" {!! old('counter_id', 0) == $counter->id ? '' : 'style="display: none;"' !!}>
                    <div class="box-header with-border">
                        <h3 class="box-title">Edit Counter</h3>
                    </div>
                    <form method="post" action="{{ route('admin.players.update') }}">
                        <div class="box-body">
                            <div class="form-group">
                                <label for="egg_ids">Egg(s)</label>
                                <select id="egg_ids" name="egg_ids[]" multiple class="form-control egg_ids">
                                    @foreach ($eggs as $egg)
                                        <option value="{{ $egg->id }}" {{ in_array($egg->id, old('egg_ids', explode(',', $counter->egg_ids))) ? 'selected' : '' }}>{{ $egg->name }}</option>
                                    @endforeach
                                </select>
                            </div>
                            <div class="form-group">
                                <label for="game">Game</label>
                                <select id="game" name="game" class="form-control game">
                                    @foreach ($games as $key => $game)
                                        <option value="{{ $key }}" {{ $key == old('game', $counter->game) ? 'selected' : '' }}>{{ $game }}</option>
                                    @endforeach
                                </select>
                            </div>
                        </div>
                        <div class="box-footer">
                            {!! csrf_field() !!}
                            <input type="hidden" name="counter_id" value="{{ $counter->id }}">
                            <button class="btn btn-danger btn-sm" type="button" onclick="cancel();">Cancel</button>
                            <button class="btn btn-success pull-right btn-sm">Edit</button>
                        </div>
                    </form>
                </div>
            @endforeach
        </div>
    </div>
@endsection

@section('footer-scripts')
    @parent
    <script>
        let createBox = $('#createBox');
        let editBoxes = $('.editBox');

        $('[data-toggle="tooltip"]').tooltip();

        $('.egg_ids').select2({
            placeholder: 'Select Egg(s)',
        });

        $('.game').select2({
            placeholder: 'Select Game',
        });

        function edit(id) {
            editBoxes.slideUp(500);
            createBox.slideUp(500);
            $('#editBox-' + id).slideDown(500);
        }

        function cancel() {
            editBoxes.slideUp(500);
            createBox.slideDown(500);
        }

        $('[data-action="delete"]').click(function (event) {
            event.preventDefault();
            let self = $(this);
            swal({
                title: '',
                type: 'warning',
                text: 'Are you sure you want to delete this counter?',
                showCancelButton: true,
                confirmButtonText: 'Delete',
                confirmButtonColor: '#d9534f',
                closeOnConfirm: false,
                showLoaderOnConfirm: true,
                cancelButtonText: 'Cancel',
            }, function () {
                $.ajax({
                    method: 'DELETE',
                    url: '{{ route('admin.players.delete') }}',
                    headers: {'X-CSRF-TOKEN': $('meta[name="_token"]').attr('content')},
                    data: {
                        id: self.data('id')
                    }
                }).done((data) => {
                    self.parent().parent().slideUp();

                    swal({
                        type: 'success',
                        title: 'Success!',
                        text: 'You have successfully deleted this counter.'
                    });
                }).fail((jqXHR) => {
                    swal({
                        type: 'error',
                        title: 'Ooops!',
                        text: (typeof jqXHR.responseJSON.error !== 'undefined') ? jqXHR.responseJSON.error : 'A system error has occurred! Please try again later...'
                    });
                });
            });
        });
    </script>
@endsection
