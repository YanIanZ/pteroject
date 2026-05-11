@section('sourby::lg.changer.logo')

@isset($sourby_settings['logourl'])@if($sourby_settings['logourl'] == 1)

@else
<script>


const intervals = setInterval(function() {

   document.getElementById('logo').src='@isset($sourby_settings['logourl']){{$sourby_settings['logourl']}} @else {{ config('sourby.websitelogo') }} @endisset'

  }, 22);
</script>

 @endif
@endisset


@isset($sourby_settings['enableloginimg'])@if($sourby_settings['enableloginimg'] == 1)
<script>
setTimeout(
    function() {
		document.getElementById('logo').style.display='none';
    }, 20);

    const interval = setInterval(function() {

	document.getElementById('logo').style.display='none';

   }, 10);
</script>
<style>.jbDTOK {padding: 1.5rem;}</style>
@else

@endif
@endisset

@endsection
