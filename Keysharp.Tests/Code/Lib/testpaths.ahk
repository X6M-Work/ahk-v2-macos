_TestFixturePath(_relative := "")
{
	SplitPath(A_LineFile, , &_directory)
	SplitPath(_directory, , &_directory)
	return _directory "/" _relative
}
