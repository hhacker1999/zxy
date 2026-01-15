package traktusecase

func (u *Usecase) syncTraktData(token string) error {
	// movies := []models.TraktPlaybackHistoryItem{}
	// series := []models.TraktPlaybackHistoryItem{}
	// var merr error
	// var serr error
	// wg := sync.WaitGroup{}
	//
	// go func() {
	// 	wg.Add(1)
	// 	defer wg.Done()
	// 	movies, merr = u.getWatchedMovies(token)
	// }()
	// go func() {
	// 	wg.Add(1)
	// 	defer wg.Done()
	// 	series, serr = u.getWatchedSeries(token)
	// }()
	// wg.Wait()
	//
	// if merr != nil {
	// 	return merr
	// }
	// if serr != nil {
	// 	return serr
	// }
	//
	// go func() {
	// 	wg.Add(1)
	// 	defer wg.Done()
	// 	merr = u.playbackRepo.InserTraktMoviePlaybackHistory(movies)
	// }()
	// go func() {
	// 	wg.Add(1)
	// 	defer wg.Done()
	// 	serr = u.playbackRepo.InsertTraktSeriesPlaybackHistory(series)
	// }()
	// wg.Wait()
	//
	// if merr != nil {
	// 	return merr
	// }
	// if serr != nil {
	// 	return serr
	// }
	//
	return nil
}
