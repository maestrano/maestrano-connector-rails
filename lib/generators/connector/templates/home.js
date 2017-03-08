function historicalDataDisplay()
{
  if (document.getElementById('historical-data').checked)
  {
      document.getElementById('historical-data-display-checked').style.display = 'block';
      document.getElementById('historical-data-display-unchecked').style.display = 'none';
  } else {
      document.getElementById('historical-data-display-unchecked').style.display = 'block';
      document.getElementById('historical-data-display-checked').style.display = 'none';
  }
}

var checkHistorical

function closeModal(sender)
{
  checkHistorical = sender.id == 'confirm'
  $('#myModal').modal('hide');
}

$(document).ready(function(){
    $("#myModal").on('hidden.bs.modal', function (e) {
      if (!checkHistorical) {
		document.getElementById('historical-data').checked = false
		historicalDataDisplay()
      }
      checkHistorical = false
    });
});


$(function () {
  $('[data-toggle="tooltip"]').tooltip()
})
